module Ubiquo::ArticlesHelper
  def article_filters
    filters_for "Article" do |f|
      f.text
      f.date
    end
  end

  def article_list(collection, pages, options = {})
    render(:partial => "shared/ubiquo/lists/standard", :locals => {
        :name => 'article',
        :headers => [:title, :description, :published_at],
        :rows => collection.collect do |article|
          {
            :id => article.id,
            :columns => [
              article.title,
              article.description,
              article.published_at,
            ],
            :actions => article_actions(article)
          }
        end,
        :pages => pages,
        :link_to_new => link_to(t("ubiquo.article.index.new"),
                                new_ubiquo_article_path, :class => 'new')
      })
  end

  private

  def article_actions(article, options = {})
    actions = []
    actions << link_to(t("ubiquo.edit"), [:edit, :ubiquo, article], :class => 'btn-edit')
    actions << link_to(t("ubiquo.remove"), [:ubiquo, article],
      :confirm => t("ubiquo.article.index.confirm_removal"), :method => :delete, 
      :class => 'btn-delete'
      )
    actions
  end
end
