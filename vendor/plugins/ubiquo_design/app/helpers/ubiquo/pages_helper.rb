module Ubiquo::PagesHelper

  def page_filters
    if Ubiquo::Config.context(:ubiquo_design).get(:page_string_filter_enabled)
      filters_for 'Page' do |f|
        f.text :caption => t('ubiquo.design.name')
      end
    end
  end

  def pages_list(collection, pages, options = {})
    render(:partial => "shared/ubiquo/lists/standard",
      :locals => {
        :name => 'page',
        :headers => [:name, :url_name, :published_id],
        :rows => collection.collect do |page|
          {
            :id => page.id,
            :columns => [
              (if page.published? && page.published.is_linkable?
                 link_to_page(page.name, page, {}, :popup => true)
               else
                 page.name
               end),
              page.url_name,
              publish_status(page),
            ],
            :actions => uhook_page_actions(page)
          }
        end,
        :pages => pages,
        :link_to_new => link_to(t("ubiquo.design.new_page"),
          new_ubiquo_page_path, :class => 'new')})
  end

  def publish_status(page)
    status,icon_name = if page.published? && !page.is_modified?
      ['published', 'ico_published']
    elsif page.published? && page.is_modified?
      ['pending_publish', 'ico_pending']
    else
      ['unpublished', 'ico_unpublished']
    end
    ubiquo_image_tag("#{icon_name}.png",
                     :alt => t("ubiquo.design.status.#{status}"),
                     :title => t("ubiquo.design.status.#{status}")) + " " +
      t("ubiquo.design.status.#{status}")
  end

end
