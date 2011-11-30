module Ubiquo::CategoriesHelper

  def category_filters
    filters_for 'Category' do |f|
      f.text
      uhook_category_filters f
    end
  end

  def category_list(collection, pages, options = {})
    render(:partial => "shared/ubiquo/lists/standard", :locals => {
        :name => 'category',
        :headers => [:name, :description],
        :rows => collection.collect do |category|
          {
            :id => category.id,
            :columns => [
              category.name,
              category.description,
            ],
            :actions => uhook_category_index_actions(options[:category_set], category)
          }
        end,
        :pages => pages,
        :hide_actions => !options[:category_set].is_editable?,
        :link_to_new => (
          link_to(
            t("ubiquo.category.index.new"),
            new_ubiquo_category_set_category_path, :class => 'new'
          ) if options[:category_set].is_editable?)
      })
  end

end
