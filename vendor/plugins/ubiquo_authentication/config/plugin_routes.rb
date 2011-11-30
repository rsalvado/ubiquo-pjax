map.namespace :ubiquo do |ubiquo|
  ubiquo.with_options :controller => "sessions" do |s|
    s.login 'login', :action => "new", :conditions => {:method => :get}
    s.connect 'login', :action => "create", :conditions => {:method => :post}
    s.logout 'logout', :action => "destroy", :conditions => {:method => :delete}
  end
  ubiquo.resource :session
  ubiquo.resource :superadmin_mode
  ubiquo.resource :superadmin_home
  ubiquo.resource :password
  ubiquo.resource :ubiquo_user_profile
  ubiquo.resources :ubiquo_users
end
