module UbiquoDesign
  # This module hooks into the rendering of a Page to use the widget cache
  module CacheRendering

    def self.append_features(base)
      super
      base.send :include, InstanceMethods
    end

    module InstanceMethods

      def self.included(klass)
        klass.alias_method_chain :render_widget, :cache
      end

      def render_widget_with_cache(widget)
        start = Time.now.to_f
        rendered = render_widget_without_cache widget
        begin
          UbiquoDesign.cache_manager.cache(widget, rendered, :scope => self)
          Rails.logger.debug "Elapsed time for widget #{widget.key} ##{widget.id}: #{(Time.now.to_f- start)}"
        rescue
          Rails.logger.error "Widget cache store request fail for widget: #{widget}"
        end
        rendered
      end

    end

  end
end
