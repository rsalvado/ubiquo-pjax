module UbiquoAuthentication
  module Extensions
    module Helper
      
      #Adds the ubiquo_users management link to the navigator.This
      #runs the ubiquo_authentication.user_navigation_permission for
      #checking if the user can access to that page. 
      def ubiquo_users_link(navigator)
        navigator.add_link do |link|
          link.text = I18n.t("ubiquo.auth.users")
          link.highlights << {:controller => "ubiquo/ubiquo_users"}
          link.url = ubiquo_ubiquo_users_path
        end if ubiquo_config_call(:user_navigator_permission, {:context => :ubiquo_authentication})
      end
      
      #Adds the logout link to the navigator.
      def logout_link(navigator)
        navigator.add_link(:method => :delete) do |link|
          link.text = I18n.t("ubiquo.auth.logout")
          link.url = ubiquo_logout_path
        end
      end
      
      #Adds user_name link that points to the profile page to the
      #navigator.
      def ubiquo_user_name_link(navigator)
        navigator.add_link do |link|
          link.text = current_ubiquo_user.full_name
          link.class = "ubiquo_user"
          link.url = edit_ubiquo_ubiquo_user_profile_path
          link.highlights << {:controller => "ubiquo/ubiquo_user_profiles"}
        end
      end
      
      #Adds a superadmin home tab to the tabnav. It doesn't validates
      #that the user is a superadmin, it's supposed.
      def superadmin_home_tab(tabnav)
        tabnav.add_tab do |tab|
          tab.text =  I18n.t("ubiquo.auth.superadmin_home")
          tab.title =  I18n.t("ubiquo.auth.superadmin_home_title")
          tab.highlights_on({:controller => "ubiquo/superadmin_homes"})
          tab.link = ubiquo_superadmin_home_path  
        end
      end
      
      #Adds a superadmin mode toggle link to the navigator. It's show
      #the link only if the user is superadmin.
      def toggle_superadmin_mode_link(navigator)
        return unless current_ubiquo_user.is_superadmin?
        if superadmin_mode?
          navigator.add_link(:method => :delete) do |link|
            link.text = t("ubiquo.auth.back_from_superadmin_mode")
            link.url = ubiquo_superadmin_mode_path
          end
        else
          navigator.add_link(:method => :post) do |link|
            link.text = t("ubiquo.auth.go_to_superadmin_mode")
            link.url = ubiquo_superadmin_mode_path
          end
        end
      end
      
      # returns if the superadmin mode is actived or not.
      def superadmin_mode?
        session[:superadmin_mode]==true
      end
    end
  end
end
