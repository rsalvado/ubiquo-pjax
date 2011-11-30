module Ubiquo
  module Helpers
    module ShowHelpers

      # Returns an html list with the provided +title+, containing +elements+
      def ubiquo_show_list title, elements
        html = content_tag(:dt, title)
        html += content_tag(:dd) do
          content_tag(:ul) do
            elements.map do |element|
              content_tag(:li, element)
            end.join
          end
        end
      end

    end
  end
end
