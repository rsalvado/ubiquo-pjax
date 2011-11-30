module UbiquoJobs
  module Extensions
    autoload :Helper, 'ubiquo_jobs/extensions/helper'
  end
end

Ubiquo::Extensions::Loader.append_helper(:UbiquoController, UbiquoJobs::Extensions::Helper)
