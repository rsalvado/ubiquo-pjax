module UbiquoMedia
  module Extensions
    module Helper
      
      # Adds a tab for the media section
      def media_tab(navtab)
        navtab.add_tab do |tab|
          tab.text = I18n.t("ubiquo.media.media")
          tab.title = I18n.t("ubiquo.media.media_title")
          tab.highlights_on({:controller => "ubiquo/assets"})
          tab.link = ubiquo_assets_path
        end if ubiquo_config_call(:assets_permit, {:context => :ubiquo_media})
      end
      
      # Return the thumbnail url for a given asset
      def thumbnail_url(asset)
        if asset.asset_type.key == "image"
          asset.resource.url(:thumb)
        else
          "/images/ubiquo/media/ico-#{asset.asset_type.key}.png"
        end
      end

      # Returns html containing a list of displayed images
      #   instance: ActiveRecord that has the media_attachment
      #   field: name of the media_attachment field
      #   title: list title
      def ubiquo_show_media_attachment_images instance, field, title
        html = content_tag(:dt, title)
        html += content_tag(:dd, :class => 'images') do
          content_tag(:ul) do
            instance.send(field).map do |asset|
              content_tag(:li) do
                content_tag(:span, image_tag(url_for_media_attachment(asset))) +
                content_tag(:p, instance.name_for_asset(:field, asset))
              end
            end.join
          end + tag(:br, :style => 'clear:both')
        end
      end

      # Returns html containing a list of links to documents
      #   instance: ActiveRecord that has the media_attachment
      #   field: name of the media_attachment field
      #   title: list title
      def ubiquo_show_media_attachment_docs instance, field, title
        html = content_tag(:dt, title)
        html += content_tag(:dd) do
          content_tag(:ul, :class => 'attachment') do
            instance.send(field).map do |asset|
              content_tag(:li) do
                link_to asset.name, url_for_media_attachment(asset)
              end
            end.join
          end
        end
      end

    end
  end
end
