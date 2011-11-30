module Ubiquo::StaticPagesHelper
  def static_page_filters
    if Ubiquo::Config.context(:ubiquo_design).get(:page_string_filter_enabled)
      filters_for 'Page' do |f|
        f.text :caption => t('ubiquo.design.name')
      end
    end
  end

  def static_pages_list(collection, pages, options = {})
    render(:partial => "shared/ubiquo/lists/standard",
           :locals => {
             :name => 'page',
             :headers => [:name, :url_name, :published_id],
             :rows => collection.collect do |static_page|
               {
                 :id => static_page.id,
                 :columns => [
                   (if static_page.published? && static_page.published.is_linkable?
                     link_to_page(static_page.name, static_page, {}, :popup => true)
                    else
                      static_page.name
                    end),
                   static_page.url_name,
                   publish_status(static_page),
                 ],
                 :actions => uhook_static_page_actions(static_page)
               }
             end,
             :pages => pages,
             :link_to_new => link_to(t("ubiquo.design.static_pages.new"),
                                     new_ubiquo_static_page_path, :class => 'new')})
  end

end
