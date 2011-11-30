module Ubiquo
  module Filters
    class LinksOrSelectFilter < SelectFilter

      def render
        if @options[:collection].size <= (@options[:max_size_for_links] || Ubiquo::Config.get(:max_size_for_links_filter))
          filter = LinkFilter.new(@model,@context)
          filter.configure(@options[:field],@options[:collection], @options)
          filter.render
        else
          super
        end
      end

    end
  end
end
