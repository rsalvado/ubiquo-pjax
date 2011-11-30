module UbiquoMedia
  module MediaSelector
    autoload :Helper, 'ubiquo_media/media_selector/helper'
    autoload :ActiveRecord, 'ubiquo_media/media_selector/active_record'
  end
end

ActiveRecord::Base.send(:include, UbiquoMedia::MediaSelector::ActiveRecord)
ActionView::Base.send(:include, UbiquoMedia::MediaSelector::Helper)
