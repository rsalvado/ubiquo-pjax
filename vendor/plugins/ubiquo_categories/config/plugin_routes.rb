map.namespace :ubiquo do |ubiquo|
  ubiquo.resources :category_sets, :has_many => :categories
end
