require File.dirname(__FILE__) + "/../test_helper.rb"

class UbiquoI18n::Extensions::HelpersTest < ActionView::TestCase

  def test_locale_selector_displays_select
    html_content = HTML::Document.new(locale_selector)
    assert_select html_content.root, "form" do
      assert_select 'select'
    end
  end

  def test_locale_selector_deletes_page_by_default
    html_content = HTML::Document.new(locale_selector)
    assert_select html_content.root,  ['form[action=?]', /page.+/], false
  end

  def test_locale_selector_accepts_keep_page_option
    html_content = HTML::Document.new(locale_selector(:keep_page => true))
    assert_select html_content.root, 'form[action=?]', /page.+/
  end

  # Some stubs for helpers
  UbiquoI18n::Extensions::Helpers.module_eval do
    include Ubiquo::Helpers::CorePublicHelpers
    
    def params
      {:page => '1'}
    end

    def url_for(options = {})
      options.to_s
    end

    def current_locale
      'ca'
    end
  end

end
