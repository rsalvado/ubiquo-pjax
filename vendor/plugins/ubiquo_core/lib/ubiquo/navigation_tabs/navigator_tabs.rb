module Ubiquo
  module NavigationTabs
    class NavigatorTabs
      attr_accessor :tabs, :html_options, :tab_options
      
      def initialize(options = {})
        # Get default options for each Tab
        if options[:tab_options] && options[:tab_options].kind_of?(Hash)
          @tab_options = options[:tab_options]
        else
          @tab_options = {}
        end
        options.delete(:tab_options)
        
        # Merge html options with other configuration options
        options.merge!(options.delete(:html)||{})

        # Options for <ul>
        @html_options = { :id => options[:id], 
          :class => options[:class] }
        
        # Tabs attribute will contain an array of Tab instances
        @tabs = []
        
        @previous_code = "asdsadasd"
        @next_code = "post"
      end
      
      # Method to add a tab inside a navigator object
      def add_tab(options = {}, &block)
        id = @tab_options[:id] ? (@tab_options[:id].to_s + "_" + (@tabs.size + 1).to_s) : nil
        
        tab = Tab.new({ :id => id,                     
                        :class => @tab_options[:class]
                      }.merge(options))
        @tabs << tab
        block.call(tab)
        tab
      end
      
      # sort your tabs alphabetically
      def sort!
        @tabs.sort! { |x,y| x.text <=> y.text  }
      end
      
    end
  end
end
