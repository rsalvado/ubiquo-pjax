#= UbiquoUser and Roles
#
#A _ubiquo_user_ has login/password, active and admin flag attributes. Admin ubiquo users are allowed access to all pages and make CRUD operations on the whole data-model (no matter if they have roles are assigned for this task or not).
#
#A _role_ has a collection of permissions which grant access to certain parts of Ubiquo. A ubiquo user can have so many roles assigned as needed (many-to-many relationship). To add, delete or edit permissions you have to edit the fixture file ({{{db/dev_bootstrap/permissions.yml}}}).
#
#== Access control on controllers
#
#Access to the controllers (and its actions) can be restricted separately. On this example, a controller is restricted for ubiquo users with _show_ permission (that's it, which have a role assigned containing this permission) for _show_ action, and _manage_ permission for all other actions:
#
#  class Ubiquo::ExampleController < UbiquoController
#    access_control :show => 'guest', :DEFAULT => "management"
#    ...
#  end
#
#Make sure that the !ApplicationController includes the access control library:
#
#  class ApplicationController < ActionController::Base
#    include AccessControl
#    ...
#  end
#
#== Access control on views
#
#On the views, the actions or navigation tabs for which the current ubiquo user have no rights shouldn't be visible. Use _permit?_ in your views to check if an ubiquo_user has one permission or not:
#
#  if permit?('show')
#    link_to(t('Show object'), ubiquo_object(object))
#  end
#
#You can also use _restrict_to_ with a block:
#
#  restrict_to('show') do
#    link_to(t('Show object'), ubiquo_object(object))
#  end
module UbiquoAccessControl
  module AccessControl


    def self.included(subject)
      subject.extend(ClassMethods)
      if subject.respond_to? :helper_method
        subject.helper_method(:permit?)
        subject.helper_method(:restrict_to)
      end
    end

    module ClassMethods

      # Function to regulate the required permissions for actions in a controller
      #
      # Examples:
      #   for the key in "actions":
      #     access_control {
      #      :DEFAULT => ... # control all actions
      #      :index => .... #control index action
      #      [:new, :create] => .... #control new and create actions
      #     }
      #
      #   for the value:
      #     - one permission
      #       access_control :DEFAULT => 'permission_key'
      #       access_control :DEFAULT => :permission_key
      #
      #     - more permissions
      #       access_control :DEFAULT => ['permission_key_1', 'permission_key_2']
      #       access_control :DEFAULT => [:permission_key_1, :permission_key_2]
      #       access_control :DEFAULT => %w{permission_key_1 permission_key_2}
      #
      #     - only admins
      #       access_control :DEFAULT => nil
      #
      def access_control(actions={})
        # Add class-wide permission callback to before_filter
        defaults = {}
        if block_given?
          yield defaults
          default_block_given = true
        end
        before_filter do |c|
          c.default_access_context = defaults if default_block_given
          @access = AccessSentry.new(c, actions)
          if @access.allowed?(c.action_name)
            c.send(:permission_granted)  if c.respond_to?:permission_granted
          else
            if c.respond_to?:permission_denied
              c.send(:permission_denied)
            else
              if File.exists?(Rails.root.join('public', '403.html'))
                c.send(:render, {:file => Rails.root.join('public','403.html'),:status => 403})
              else
                c.send(:render, { :text => "Access denied", :status => 403})
              end
            end
          end
        end
      end
    end # ClassMethods

    # return the active access handler, fallback to RoleHandler
    # implement #retrieve_access_handler to return non-default handler
    def access_handler
      @handler ||= RoleHandler.new
    end

    # the current access context; will be created if not setup
    # will add current_ubiquo_user and merge any other elements of context
    def access_context(context = {})
      r = default_access_context
      default_access_context[:params].merge!(context)
      r
    end

    def default_access_context
      @default_access_context ||= {}
      @default_access_context[:ubiquo_user] ||= send(:current_ubiquo_user) if respond_to?(:current_ubiquo_user)
      @default_access_context[:params] ||= send(:params)
      @default_access_context
    end

    def default_access_context=(defaults)
      @default_access_context = defaults
    end

    # Returns true if the current user has the permissions in auth
    # auth can be either a single value, an array or nil
    # (See the access_control method for examples of auth values)
    def permit?(auth=nil, context = {})
      access_handler.process(UbiquoAccessControl::AccessControl::Parser.parse(auth), access_context(context))
    end

    # Used to restrict a block to users matching certain permissions
    # Used mainly in views, will return an empty string if the permission is not matched
    #
    # Example:
    #   restrict_to "admin" do
    #     link_to "foo"
    #   end
    #
    def restrict_to(auth = nil, context = {})
      result = ''
      if permit?(UbiquoAccessControl::AccessControl::Parser.parse(auth), context)
        result = yield if block_given?
      end
      result
    end

    class AccessSentry

      def initialize(subject, actions={})
        @actions = actions.inject({}) do |auth, current|
          [current.first].flatten.each { |action|
            auth[action] = UbiquoAccessControl::AccessControl::Parser.parse(current.last)
          }
          auth
        end
        @subject = subject
      end

      def allowed?(action)
        if @actions.has_key? action.to_sym
          return @subject.access_handler.process(@actions[action.to_sym].dup, @subject.access_context)
        elsif @actions.has_key? :DEFAULT
          return @subject.access_handler.process(@actions[:DEFAULT].dup, @subject.access_context)
        else
          return true
        end
      end

    end # AccessSentry


    class RoleHandler

      # Main permission validator
      # Returns false on lack of permission or an error,
      #   true if the user has the enough permissions - this includes being superadmin.
      # Will use an :ubiquo_user from the context hash to do the checks.
      #
      def process(auth, context)
        return false if context[:ubiquo_user].nil? || context[:ubiquo_user] == :false
        return true if context[:ubiquo_user].is_superadmin?
        return true if context[:ubiquo_user].has_permission?(nil) # only admins should get true
        [auth].flatten.each do |a|
          permit = context[:ubiquo_user].has_permission?(a[:permission])
          return true if permit==true
        end
        false
      end

    end # RoleHandler

    class Parser
      # parses a list of permissions that can be strings, symbols, etc.
      # (see access_control for the permission formats)
      #
      # Returns an array where each element is a hash with the following keys:
      #   :permission => name of the permission as a string
      #   :admin => true if this permission requires to be an admin
      def self.parse(permissions)
        [permissions].flatten.collect do |current|
          permission = case current
                       when String,Symbol
                         {:permission => current.to_s}
                       when NilClass
                         {:permission => nil, :admin => true}
                       else
                         current
                       end
        end.reject(&:blank?)
      end
    end # Parser

  end # AccessControl
end
