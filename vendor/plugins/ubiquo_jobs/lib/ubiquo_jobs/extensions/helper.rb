module UbiquoJobs
  module Extensions
    module Helper
      # Adds a "Jobs" tab into the superadmin area
      def superadmin_jobs_tab(tabnav)
        tabnav.add_tab do |tab|
          tab.text =  I18n.t("ubiquo.jobs.tab_name")
          tab.title =  I18n.t("ubiquo.jobs.tab_title")
          tab.highlights_on({:controller => "ubiquo/jobs"})
          tab.link = ubiquo_jobs_path  
        end
      end
    end
  end
end
