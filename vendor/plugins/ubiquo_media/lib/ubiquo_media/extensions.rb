module UbiquoMedia
  module Extensions
    autoload :Helper, 'ubiquo_media/extensions/helper'
  end
end

Ubiquo::Extensions::Loader.append_helper(:UbiquoController, UbiquoMedia::Extensions::Helper)


