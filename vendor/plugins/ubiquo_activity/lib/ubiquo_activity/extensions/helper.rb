module UbiquoActivity
  module Extensions
    module Helper

      # Adds the activity link in the upper-left menu if the user
      # has the proper permissions.
      def ubiquo_activities_link(navigator)
        navigator.add_link do |link|
          link.text = I18n.t("ubiquo.activity_info.title")
          link.highlights << {:controller => "ubiquo/activity_infos"}
          link.url = ubiquo_activity_infos_path
        end if ubiquo_config_call(:activity_info_permit, {:context => :ubiquo_activity })
      end

    end
  end
end
