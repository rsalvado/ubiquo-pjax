desc "Add schema information (as comments) to application and ubiquo model files"

task :annotate_models => :environment do
  include Ubiquo::Tasks::AnnotateModels
  do_annotations
end