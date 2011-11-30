module UbiquoCategories
  module CategorySelector
    autoload :Helper, 'ubiquo_categories/category_selector/helper'
  end
end
ActionView::Base.send(:include, UbiquoCategories::CategorySelector::Helper)
