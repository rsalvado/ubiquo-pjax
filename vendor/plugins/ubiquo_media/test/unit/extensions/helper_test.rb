require File.dirname(__FILE__) + "/../../test_helper.rb"

class UbiquoMedia::Extensions::HelperTest < ActionView::TestCase

  include UbiquoMedia::MediaSelector::Helper
  include Ubiquo::Helpers::CorePublicHelpers

  def test_ubiquo_show_media_attachment_images
    list_html = ubiquo_show_media_attachment_images(
      create_media_test,
      :images,
      'Title'
    )
    assert_equal example_images_list, list_html
  end

  def test_ubiquo_show_media_attachment_docs
    list_html = ubiquo_show_media_attachment_docs(
      create_media_test,
      :images,
      'Title'
    )
    assert_equal example_documents_list, list_html
  end

  private

  def example_images_list
    test = create_media_test
    html = content_tag(:dt, 'Title')
    html += content_tag(:dd, :class => 'images') do
      content_tag(:ul) do
        test.images.map do |asset|
          content_tag(:li) do
            content_tag(:span, image_tag(url_for_media_attachment(asset))) +
            content_tag(:p, test.name_for_asset(:field, asset))
          end
        end.join
      end + tag(:br, :style => 'clear:both')
    end
  end

  def example_documents_list
    test = create_media_test
    html = content_tag(:dt, 'Title')
    html += content_tag(:dd) do
      content_tag(:ul, :class => 'attachment') do
        test.images.map do |asset|
          content_tag(:li) do
            link_to asset.name, url_for_media_attachment(asset)
          end
        end.join
      end
    end
  end

  def create_media_test
    test = MediaTestModel.create(:field => "value")
    test.images = Asset.all
    test
  end

  ActiveRecord::Base.connection.create_table(:media_test_models, :force => true) do |t|
    t.string :field
  end

class MediaTestModel < ActiveRecord::Base
  media_attachment :images, :size => :many
end

end
