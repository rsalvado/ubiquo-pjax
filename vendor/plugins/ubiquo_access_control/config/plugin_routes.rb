map.namespace :ubiquo do |ubiquo|
  ubiquo.resources :roles
end
map.connect "/access_control/:action", :controller => 'access_control'
