module Ubiquo
  module Extensions
    module String

      # Remove all non-alphanumeric characters from the string, trying to do 
      # a wide conversion (though non complete) of non-english characters 
      def urilize    
        pattern_replacements = [
                                [/[àáâäÀÁÂÄ]/, "a"],
                                [/[èéêëÈÉÊË]/, "e"],      
                                [/[ìíîïÌÍÎÏ]/, "i"],
                                [/[òóôöÒÓÔÖ]/, "o"],
                                [/[ùúûüÙÚÛÜ]/, "u"],
                                [/[\/(){}<>]/, "_"],
                                [/[ñÑ]/, "n"],
                                [/[çÇ]/, "c"],
                                [/[^\w]/, ''], # finally, discard all non-alphanumeric characters 
                               ]
        start_string = self.downcase.strip.gsub(" ", "")    
        pattern_replacements.inject(start_string) do |s, (pattern, replacement)| 
          s.gsub(pattern, replacement)
        end      
      end
      
      # allowed options:
      # :max_chars - the maximum length of the result. Includes the omissions
      # :omission - the string to show when the text is truncated. Default "..."
      # :center - A piece of text where the truncate will be centered.
      # :highlight - some words or pieces of text that will be highlighted with an span
      # :highlight_class - The CSS class to include in the highlighing span.
      #
      # Look the StringTest file to see examples of use.
      def truncate_words(options = {})
        stripped = ActionController::Base.helpers.strip_tags(self)
        
        max_length = options[:max_chars] || 100
        omission = options[:omission] || "..."
        center = options[:center]
        highlight = [options[:highlight]].flatten.compact
        highlight_class = options[:highlight_class] || "highlight"
        
        if max_length < stripped.length
          if center
            r_limit = stripped.index(center) + center.length + ((max_length - center.length) / 2) - 1 - omission.length
            l_limit = stripped.index(center) - ((max_length - center.length) / 2) + omission.length
            
            if l_limit < 0
              r_limit -= l_limit
              r_limit += omission.length
              l_limit = 0
            end
            if r_limit > stripped.length
              l_limit -= r_limit - stripped.length
              l_limit -= omission.length
              r_limit = stripped.length
            end
            result = stripped[l_limit..r_limit]
            if l_limit >0 && stripped[l_limit-1,1] != " "
              result = result[result.index(" ")+1..-1]
            end
            if r_limit < stripped.length && stripped[r_limit + 1,1] != " "
              result = result[0..(result.rindex(" ")-1)]
            end
            
            result = omission + result + omission
          else
            limit = max_length - 1 - omission.length
            result = stripped[0..limit]
            if stripped[limit + 1,1] != " "
              if result.rindex(" ")
                result = result[0..(result.rindex(" ")-1)]
              else
                result = ""
              end
            end
            result += omission
          end
        else
          result = stripped
        end
        
        highlight.each do |h|
          result = result.gsub(h, "<span class=\"#{highlight_class}\">#{h}</span>")
        end
        result
        
        
      end
    end
  end
end
