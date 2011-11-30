require 'ubiquo_categories/extensions/active_record_through_conditions_fix'

module UbiquoCategories
  module Extensions
    autoload :ActiveRecord, 'ubiquo_categories/extensions/active_record'
    autoload :Helpers, 'ubiquo_categories/extensions/helpers'
  end
end

ActiveRecord::Base.send(:include, UbiquoCategories::Extensions::ActiveRecord)
Ubiquo::Extensions::Loader.append_helper(:UbiquoController, UbiquoCategories::Extensions::Helpers)
