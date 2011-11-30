require 'ubiquo_categories/filters/category_filter'

module UbiquoCategories
  module Filters
  end
end

Ubiquo::Filters.send(:include, UbiquoCategories::Filters)
