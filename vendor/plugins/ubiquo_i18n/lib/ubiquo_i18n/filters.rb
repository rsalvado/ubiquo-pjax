require 'ubiquo_i18n/filters/locale_filter'

module UbiquoI18n
  module Filters
  end
end

Ubiquo::Filters.send(:include, UbiquoI18n::Filters)
