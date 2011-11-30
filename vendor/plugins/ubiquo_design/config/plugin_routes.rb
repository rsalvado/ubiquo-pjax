map.namespace :ubiquo do |ubiquo|
  ubiquo.resources :static_pages, :member => { :publish => :put, :unpublish => :put }
  ubiquo.resources :pages do |pages|
    pages.resource :design, :member => {:preview => :get, :publish => :put, :unpublish => :put} do |design|
      design.resources :widgets, :collection => {:change_order => :any}, :member => {:change_name => :post}
      design.resources :blocks
    end
  end
end
  
# Proposal for public routes. 

map.with_options :controller => 'pages' do |pages|
  # Default catch-all routes
  pages.connect "*url/page/:page", :action => 'show', :requirements => {:page => /\d*/}
  pages.connect "*url", :action => 'show'
end
