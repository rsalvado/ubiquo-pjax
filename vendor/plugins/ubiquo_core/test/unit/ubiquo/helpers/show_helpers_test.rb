require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::Helpers::ShowHelpersTest < ActionView::TestCase

  def test_ubiquo_show_list
    list_html = ubiquo_show_list(
      'Title',
      ['first', 'second', link_to('nested_tag', '#'), 'last']
    )
    assert_equal example_list, list_html
  end

  private

  def example_list
    list_elements = ['first', 'second', link_to('nested_tag', '#'), 'last']
    html = content_tag(:dt, 'Title')
    html += content_tag(:dd) do
      content_tag(:ul) do
        list_elements.map do |element|
          content_tag(:li, element)
        end.join
      end
    end
  end

end
