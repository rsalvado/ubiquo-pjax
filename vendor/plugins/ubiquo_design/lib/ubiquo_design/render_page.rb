module UbiquoDesign
  module RenderPage

    def self.included(klass)
      klass.helper_method :render_block
    end
    
    private
    def render_page(page)
      cached_widgets = UbiquoDesign.cache_manager.multi_get(page,:scope => self)

      @blocks = page.blocks.collect do |block|
        block_output = render_block(block.real_block, cached_widgets)
        # Return if block is void (normally, a redirect ocurred)
        return unless block_output
        [block.block_type.to_sym, block_output.join]
      end.to_hash
      render_template_file(page.page_template, page.layout)
    end


    # Renders all the widgets contained in a block
    def render_block(block, cached_widgets = {})
      uhook_collect_widgets(block) do |widget|
        next unless widget.valid?
        (cached_widgets[widget.id] || render_widget(widget)).tap do |output|
          # A widget didn't return an string, return inmediately
          return unless output
        end
      end
    end

    def template_directory
      Rails.env.test? ? File.join(ActiveSupport::TestCase.fixture_path, "templates") :
        Rails.root.join('app', 'views', 'page_templates').to_s
    end

    def render_template_file(key, layout = 'main')
      template_file = File.join(template_directory, "#{key}.html.erb")
      self.view_paths.unshift(File.dirname(template_file))
      render_output = render :file => File.basename(template_file), :layout => layout
      self.view_paths.shift
      render_output
    end
  end
end
