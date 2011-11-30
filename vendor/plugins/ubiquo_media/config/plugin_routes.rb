map.namespace :ubiquo do |ubiquo|
  ubiquo.resources :assets, :collection => {:search => :get}, 
    :member => {:advanced_edit => :get, :advanced_update => :put, :restore => :post}
end
