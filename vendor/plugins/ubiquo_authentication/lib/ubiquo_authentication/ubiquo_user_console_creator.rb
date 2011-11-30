module UbiquoAuthentication
  # Helper class used from rake ubiquo:create_user to create ubiquo users from the console
  class UbiquoUserConsoleCreator
    
    # Creates a new ubiquo user accepts required fields as parameters.
    def self.create!(options = {})
      user = UbiquoUser.create(
               :login                 => options[:login], 
               :password              => options[:password], 
               :password_confirmation => options[:password_confirmation],
               :email                 => options[:email],
               :name                  => options[:name],
               :surname               => options[:surname],
               :is_active             => options[:is_active],
               :is_admin              => options[:is_admin])
      user.is_superadmin = options[:is_superadmin]
      user.locale = I18n.locale.to_s
      user.save!
      user
    end
    
  end
end
