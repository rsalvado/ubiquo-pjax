module Ubiquo
  module Extensions
    module ActionView
      # Return a proc that marks an html tag as an error
      def self.ubiquo_field_error_proc
        Proc.new do |html_tag, instance|
          msg = instance.error_message
          error_class = Ubiquo::Config.get(:error_field_class)
          unless (html_tag =~ /<input.*?type=\"(checkbox|radio|file)\"/)
            if html_tag =~ /<(input|textarea|select)[^>]+class=/
              class_attribute = html_tag =~ /class=['"]/
              html_tag.insert(class_attribute + 7, "#{error_class} ")
            elsif html_tag =~ /<(input|textarea|select)/
              first_whitespace = html_tag =~ /\s/
              html_tag[first_whitespace] = " class='#{error_class}' "
            end
            html_tag
          else
            # There are 3 special type input (checkbox, radio, file) for which
            # setting the class on the element won't work. In this case, create
            # a surrounding span.
            case html_tag
              when /type=\"file\"/
                "<div class=\"file_#{error_class}\">" + html_tag + "</div>"
              when /type=\"checkbox\"/
                "<span class=\"checkbox_#{error_class}\">" + html_tag + "</span>"
              when /type=\"radio\"/
                "<span class=\"radio_#{error_class}\">" + html_tag + "</span>"
              else
                "<span class=\"#{error_class}\">" + html_tag + "</span>"
            end
          end
        end
      end
    end
  end
end
