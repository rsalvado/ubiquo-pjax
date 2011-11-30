module UbiquoAccessControl
  module Extensions
    module TestCase
      # Test helper. will log a user with the given permission keys 
      def login_with_permission(*permission_keys)
        ubiquo_user = ubiquo_users(:eduard)
        ubiquo_user.roles.clear
        role = Role.new(:name => 'test')
        ubiquo_user.roles << role
        permissions_records = permission_keys.map do |key| 
          Permission.new(:key => key.to_s, :name => "test #{key}")
        end
        role.permissions << permissions_records
        @request.session[:ubiquo] ||= {}
        @request.session[:ubiquo][:ubiquo_user_id] = ubiquo_user
      end
      
    end
  end
end
