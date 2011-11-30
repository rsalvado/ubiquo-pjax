ActionController::Routing::Routes.draw do |map|

  map.namespace :ubiquo do |ubiquo|
    ubiquo.resources :articles

  end

  Translate::Routes.translation_ui(map) unless Rails.env.production?
  # Ubiquo plugins routes. See routes.rb from each plugin path.
  map.from_plugin :ubiquo_categories
  map.from_plugin :ubiquo_core
  map.from_plugin :ubiquo_authentication
  map.from_plugin :ubiquo_access_control
  map.from_plugin :ubiquo_scaffold
  map.from_plugin :ubiquo_media
  map.from_plugin :ubiquo_jobs
  map.from_plugin :ubiquo_i18n
  map.from_plugin :ubiquo_activity
  map.from_plugin :ubiquo_versions
  map.from_plugin :ubiquo_guides
  map.from_plugin :ubiquo_design
  map.from_plugin :translate

  ############# default routes
  #map.connect ':controller/:action/:id'
  #map.connect ':controller/:action/:id.:format'
end
