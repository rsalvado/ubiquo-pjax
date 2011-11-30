require 'ubiquo_categories'

config.after_initialize do
  UbiquoCategories::Connectors.load!
end

Ubiquo::Plugin.register(:ubiquo_categories, directory, config) do |config|
  config.add :category_sets_per_page
  config.add_inheritance :category_sets_per_page, :elements_per_page

  config.add :categories_per_page
  config.add_inheritance :categories_per_page, :elements_per_page

  config.add :categories_access_control, lambda{
    access_control :DEFAULT => 'categories_management'
  }
  config.add :categories_permit, lambda{
   permit?('categories_management')
  }

  # Set to false to avoid displaying editing options in Ubiquo
  config.add :administrable_category_sets, true

  # Max number after which category_selector will render a autocomplete selector
  config.add :max_categories_simple_selector, 6

  # Connectors available in the application.
  # These connectors will be tested against the Base uhooks api
  config.add :available_connectors, [:i18n, :standard]

  # Currently enabled connector
  config.add :connector, :standard
end
