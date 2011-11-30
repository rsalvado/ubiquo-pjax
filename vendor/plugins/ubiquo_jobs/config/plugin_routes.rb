map.namespace :ubiquo do |ubiquo|
  ubiquo.resources :jobs, :collection => {:history => :get}, :member => {:repeat => :put, :output => :get}
end
