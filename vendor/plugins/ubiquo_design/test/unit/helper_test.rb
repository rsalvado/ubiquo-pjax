require File.dirname(__FILE__) + '/../test_helper'

class UbiquoDesign::Extensions::HelperTest < ActionView::TestCase

  test 'url_for_page given a page' do
    self.expects(:url_for).with do |options|
      options[:controller] = '/pages' &&
        options[:action] = 'show' &&
        options[:url] = pages(:one_design).url_name
    end
    url_for_page(pages(:one_design))
  end

  test 'url_for_page given a key' do
    self.expects(:url_for).with do |options|
      options[:controller] = '/pages' &&
        options[:action] = 'show' &&
        options[:url] = pages(:one_design).url_name
    end
    url_for_page(pages(:one_design).key)
  end

  test 'link_to_page relies in url_for_page' do
    caption = 'caption'
    page_key = pages(:one_design).key
    url_for_options = {:controller => '/pages'}
    link_to_options = {:class => 'example'}

    self.expects(:url_for_page).with(page_key, url_for_options).returns('url')
    self.expects(:link_to).with(caption, 'url', link_to_options)

    link_to_page(caption, page_key, url_for_options, link_to_options)
  end

  test 'url_for_page does not encode slashes' do
    page = Page.new(:url_name => 'with/slash')
    assert url_for_page(page) =~ /with\/slash/
  end

  test 'url_for_page with page param' do
    page = pages(:one_design)
    assert_match /#{page.url_name}\/page\/2$/, url_for_page(page, :page => 2)
  end

  test 'url_for_page with custom params' do
    page = pages(:one_design)
    assert_match /#{page.url_name}\?id=2$/, url_for_page(page, :id => 2)
  end

  test 'url_for_page with url param concatenates to the url' do
    page = pages(:one_design)
    assert_match /#{page.url_name}\/my\/params/, url_for_page(page, :url => 'my/params')
  end

end
