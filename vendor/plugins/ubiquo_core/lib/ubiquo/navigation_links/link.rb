module Ubiquo
  module NavigationLinks
    class Link
      
      attr_accessor :text, :url, :id, :class, :html,
      :highlights, :highlight_option_active, :highlighted_class,
      :disabled, :disabled_class
      
      def initialize(options = {})

        # Merge html options with other configuration options
        options.merge!(options.delete(:html)||{})

        @text  = options[:text] || "link_text"
        @url = options[:url]
        
        @id = options[:id] 
        @class = options[:class]
        
        @disabled = options[:disabled]
        @disabled_class = options[:disabled_class]
        
        @html = { :title => options[:title], :method => options[:method] }
        
        # HIGHLIGHT OPTIONS 
        @highlight_option_active = options[:highlight_option_active] || true
        # Name of class for highlighting the link when ubiquo user is in a 'highlight place'
        @highlighted_class = options[:highlighted_class] || "active"
        
        # Set highlights as an array of hashes with :controller=>:value pairs
        @highlights = []
        if options[:highlights].kind_of?(String)
          highlights_on({:controller => options[:highlights]})
        elsif options[:highlights].kind_of?(Hash)
          highlights_on(options[:highlights])
        else
          @highlights = options[:highlights]||@highlights
        end

        # It does highlight on itself
        @highlights << @url if has_url?
        
      end

      def title=(param)
        @html[:title] = param
      end
      
      def title
        @html[:title]
      end
      
      def url (url_path = nil)
        if url_path
          @url = url_path if @url.blank?
        else
          @url 
        end
      end
      
      # order when calling link_if when a tab is created determines the link that will be shown 
      def url_if(bool, url_path)
        @url = url_path if @url.blank? && bool
      end
      
      def has_url?
        !@url.blank?
      end
      
      
      # Puts inside highlights array the controllers where tab will be highlightened
      def highlights_on controller_path
        if controller_path.kind_of?(String)
          @highlights << {:controller => controller_path} 
        else
          @highlights << controller_path
        end
      end
      
      # Verifies if a tab must be highlighted in the current controller 
      def is_highlighted?(params)
        @highlights.each do |hl|
          highlighted = true
          if hl.kind_of? Hash
            hl.each do |key,value|  
              v = value.to_s
              v.gsub!(/^\//,"") if key == :controller     
              
              highlighted &&= params[key] && value.to_s == params[key].to_s
            end
          end
          return true if highlighted
        end
        false
      end
      
      def is_disabled?
        (@disabled||false)
      end
      
    end
  end
end
