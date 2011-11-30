module Ubiquo
  module NavigationTabs
    class Tab

      attr_accessor :id, :title, :class, :html, :link, :text,
      :highlights, :highlight_option_active, :highlighted_class
      
      def initialize(options = {})

        # Merge html options with other configuration options
        options.merge!(options.delete(:html)||{})

        @text = options[:text] || "tab_text"
        @link = options[:link]
        @id = options[:id] 
        @title = options[:title]
        @class = options[:class]
        
        @html = { :id => @id, :title => @title, :class => @class, :method => options[:method]  }
        
        # HIGHLIGHT OPTIONS 
        @highlight_option_active = options[:highlight_option_active] || true
        # Name of class when tab is active
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
        @highlights << @link if has_link?
        
      end

      def id=(param)
        @id =  param
        @html[:id] = param
      end

      def title=(param)
        @title =  param
        @html[:title] = param
      end

      def class=(param)
        @class =  param
        @html[:class] = param
      end    
      
      def link(link_url=nil)
        if link_url
          @link = link_url if @link.blank?
        else
          @link 
        end
      end
      
      # Method to set link information to Tab if it hasn't got any and condition value is true
      def link_if(bool, link_url)
        @link = link_url if @link.blank? && bool
      end
      
      def has_link?
        !@link.blank?
      end
      
      
      # Puts the name of controllers where tab will be highlightened inside "highlights" array
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
    end
  end
end
