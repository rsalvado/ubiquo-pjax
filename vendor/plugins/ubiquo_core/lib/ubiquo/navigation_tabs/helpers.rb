#= Navigator tabs helper methods
# 
#This library add methods to create navigation tabs sections 
#
module Ubiquo
  module NavigationTabs
    module Helpers  

      protected 
      
      # Render a partial view that contains navigaton tab elements
      # 
      # In view file: 
      # <%= render_navigation_tabs_section :main %>
      # 
      # renders "navigators/main_navtabs" partial 
      # 
      # :options 
      # ===
      #   :partial => specify the view directory for partial file 
      def render_navigation_tabs_section (navtab_file_name, options = {})
        partial_template = options[:partial] || "navigators/#{navtab_file_name}_navtabs"
        render :partial => partial_template
      end

      # Create a Navigator instance
      def create_tab_navigator (options = {}, &block)
        navigator = NavigatorTabs.new(options)
        block.call(navigator)
        navigator
      end
      
      # Render a list of tabs with html common options (:id and :class)
      # ( the navigator must be configured previously with 'create_tab_navigator' method )
      # 
      # The option :sort can be used to sort tabs by alphabet
      def render_tab_navigator(navigator, options = {})
        
        navigator.html_options[:id]    ||= options[:id]
        navigator.html_options[:class] ||= options[:class]
        
        @html = tag('ul', navigator.html_options , true)
        navigator.sort! if options[:sort] == true
        
        navigator.tabs.each do |tab|      
          li_options = {}

          li_options[:id] = "#{tab.id}" if tab.id
          li_options[:title] = "#{tab.title}" if tab.title
          li_options[:class] = "#{tab.class}" if tab.class

          if tab.is_highlighted?(params) && tab.highlight_option_active
            li_options[:class] = "#{tab.highlighted_class}" if tab.highlighted_class
          end

          attach tag('li', li_options, true)
          if tab.has_link?
            attach link_to(tab.text, tab.link, tab.html)
          else
            attach content_tag('span', tab.text, tab.html) 
          end
          attach "</li>\n"
        end
        attach '</ul>'

        @html
      end

      def attach(string)
        @html += string
      end
      
    end
  end
end
