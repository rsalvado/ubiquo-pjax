module Ubiquo
  module Extensions
    module DateParser
      # Get a string for a date and return a time object
      # options[:format]: String representation (default "%d/%m/%Y")
      # options[:time_offset]: Offset to apply to parsed time
      # TODO: This should be removed in favor of I18n.parse_date
      #       currently ubiquo filter functionality rely on this method.
      def parse_date(string_date, options = {})
        return if string_date.blank?
        return string_date if string_date.instance_of?(Time)
        return string_date if string_date.instance_of?(ActiveSupport::TimeWithZone)

        format = options.delete(:format) || "%d/%m/%Y"
        time_offset = options.delete(:time_offset)
        begin
          time = Date.strptime(string_date, format)
        rescue ArgumentError, TypeError
          return
        end
        time += time_offset if time_offset
        time
      end
    end
  end
end
