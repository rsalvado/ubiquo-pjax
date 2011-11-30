require 'ubiquo_design/extensions'
require 'ubiquo_design/ubiquo_widgets'
require 'ubiquo_design/render_page'
require 'ubiquo_design/version'
require 'ubiquo_design/cache_managers/base'
require 'ubiquo_design/cache_expiration'
require 'ubiquo_design/cache_rendering'

ActionController::Base.send(:include, UbiquoDesign::UbiquoWidgets)

if ActionController::Base.perform_caching
  ActionController::Base.send(:include, UbiquoDesign::CacheRendering)
  ActiveRecord::Base.send(:include, UbiquoDesign::CacheExpiration::ActiveRecord)
end
