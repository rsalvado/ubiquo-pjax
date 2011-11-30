module Ubiquo
  module NavigationLinks
    class NavigatorLinks
      attr_accessor :links, :html_options, :link_options
      
      def initialize(options = {})

        # Get default options for each Link
        if options[:link_options] && options[:link_options].kind_of?(Hash)
          @link_options = options[:link_options]
        else
          @link_options = {}
        end
        options.delete(:link_options)
        
        # Merge html options with other configuration options
        options.merge!(options.delete(:html)||{})

        # Options for <ul>
        @html_options = { :id => options[:id], 
          :class => options[:class] }
        
        # Links attribute will contain an array of Link instances
        @links = []
        
      end
      
      # Method to add a link inside a navigator object
      def add_link(options = {}, &block)
        id = @link_options[:id] ? (@link_options[:id].to_s + "_" + (@links.size + 1).to_s) : nil
        link = Ubiquo::NavigationLinks::Link.new(
          { :id => id, 
            :class => @link_options[:class]
          }.merge(options))
        @links << link
        block.call(link)
        link
      end
    end
  end
end
