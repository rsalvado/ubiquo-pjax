require File.dirname(__FILE__) + "/../../test_helper.rb"
require 'ubiquo_i18n/filters/locale_filter'

class LocaleFilterTest < Ubiquo::Filters::UbiquoFilterTestCase

  include UbiquoI18n::Extensions::Helpers

  def setup
    @filter = LocaleFilter.new(@model, @context)
    @filter.configure
  end

  test "Should be able to render a Boolean filter" do
    doc = HTML::Document.new(@filter.render).root
    assert_select doc, 'div#links_filter_content a', Locale.active.size
  end

  test "Should be able to get a message when the filter is set" do
    @context.params.merge!({ 'filter_locale' => 'en_US' })
    assert_match /en_US/, @filter.message.first
  end

end
