module UbiquoVersions
  module Extensions
    module Helpers
      
      # Displays a list of versions of the instance "model"
      def show_versions(model, options = {})
        render :partial => "shared/ubiquo/model_versions", :locals => {:model => model}
      end
    end
  end
end
