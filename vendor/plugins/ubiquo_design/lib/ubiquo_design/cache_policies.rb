# Manages the declaration of widget cache policies
module UbiquoDesign
  module CachePolicies

    @@policies  ||= {}

    class << self

      # Starts the definition of widget cache policies
      #   context: possible context to create multiple policies
      def define(context = nil, &block)
        with_scope(context) do
          store_definition(block.call || {})
        end
      end

      # Returns a hash with the stored policies
      def get(context = nil)
        with_scope(context) do
          current_base
        end
      end

      # Returns a list of widget types which have policies that affect a given +instance+
      def get_by_model(instance, context = nil)
        ([widgets = [], version_widgets = []]).tap do
          get(context).each_pair do |widget, policies|
            detected = (policies[:models] || []).to_a.detect{|model| instance.is_a?(model.first.to_s.constantize)}
            if detected.present?:
              related = detected.last
              if related[:params].blank? && related[:procs].blank?
                version_widgets << widget
              else
                widgets << widget
              end
            end
          end
        end
      end

      # Sets the current context during a declaration
      def with_scope(scope)
        (@@scopes ||= []) << scope
        yield ensure @@scopes.pop
      end

      # Cleans the current structure
      #   context: possible context for multiple structures
      def clear(context = nil)
        with_scope(context) { current_base.clear }
      end

      # Stores a hash with widget cache policies
      def store_definition policies
        base = current_base
        policies.each_pair do |widget, conditions|
          policy = base[widget] || {
            :self => true,
            :params => [],
            :models => {},
            :procs => [],
            :widget_params => true
          }
          add_conditions(policy, conditions)
          base[widget] = policy
        end
      end

      # Adds the +conditions+ to the current widget cache +policy+
      def add_conditions policy, conditions, current_model = nil
        case conditions
        when Symbol
          if conditions == :self
            policy[:self] = true
          elsif conditions == :params
            policy[:widget_params] = true
          else
            policy[:models][conditions.to_s] = {:params => [],
              :procs => [],
              :identifier => nil}
          end
        when Proc
          policy[:procs] << conditions
        when String
          policy[:models][conditions] = {:params => [],
            :procs => [],
            :identifier => nil}
        when Array
          conditions.each do |condition|
            add_conditions policy, condition
          end
        when Hash
          conditions.each do |key, val|
            if val.is_a?(Hash)
              policy[:models][key.to_s] = {:params => [],
                :procs => [],
                :identifier => nil}
              add_conditions policy, val, key.to_s
            else
              if key == :expires_in
                policy[:expires_in] = val
              else
                if key.is_a?(Proc) || val.is_a?(Proc)
                  policy[:models][current_model][:procs] << [val, key]
                else
                  policy[:models][current_model][:params] << {val => key}
                end
              end
            end
          end
        end
          
      end

      # Returns the current base hash, given the applied scopes
      def current_base
        current = @@policies
        @@scopes.each do |scope|
          next unless scope
          current[scope] = {} unless current[scope]
          current = current[scope]
        end
        current
      end

    end
  end

end
