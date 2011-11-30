map.namespace :ubiquo do |ubiquo|
  ubiquo.home '', :controller => "home", :action => "index"
  ubiquo.with_options :controller => "attachment", :action => "show", :conditions => {:method => :get} do |attachment|
    attachment.attachment "/attachment/*path"
  end
end
