module PagesHelper
  def metatags(page)
    tag(:meta, :name => 'description', :content => page.meta_description) +
      tag(:meta, :name => 'keywords', :content => page.meta_keywords)
  end

  # Displays the image for a given generic element
  def list_element_image(element)
    if element.respond_to?(:image) && element.image.try(:first)
      image_tag(url_for_media_attachment(element.image.first))
    end
  end

  # Displays the title for a given generic element
  # Allowed options:
  #   :show_link => Do not link the title to a detail page. Defaults to true
  def list_element_title(element, options = {})
    options = {:show_link => true}.merge(options)
    text = try_methods([:title, :name], element)
    if options[:show_link]
      link = find_detail_page(element)
      link_to_if(link, text, link)
    else
      text
    end
  end

  # Displays the text or body for a given generic element
  def list_element_body(element)
    try_methods([:body, :text], element)
  end

  protected

  def try_methods(methods, element)
    methods.each do |method|
      return element.send(method) if element.respond_to? method
    end
  end

  def find_detail_page(element)
    widget = ::GenericDetail.all.select{|gd| gd.model == element.class.name && gd.page.is_the_published?}.first
    url_for_page(widget.page, :url => element.id) if widget
  end
end
