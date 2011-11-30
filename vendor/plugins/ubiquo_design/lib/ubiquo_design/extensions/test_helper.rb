module UbiquoDesign
  module Extensions
    module TestHelper
      def widget_form_mock
        def @controller.render_widget_form(*args)
          render :inline => "Hi"
        end
      end

      def template_mock(page)
        def @controller.render_template_file(*args)
          template_file = File.join(ActiveSupport::TestCase.fixture_path, "templates", "test", "public.html.erb")
          render :file => template_file
        end
        def @controller.render_ubiquo_design_template(page)
          render_to_string :file => File.join(ActiveSupport::TestCase.fixture_path, "templates", "test", "ubiquo.html.erb"), :locals => {:page => page}
        end
      end

      def run_generator(name, widget, options)
        @controller.stubs(:session).returns(@controller.request.session)
        @controller.send(name.to_s+"_generator", widget, options)
      end

      def run_menu_generator(name, options)
        @controller.stubs(:session).returns(@controller.request.session)
        @controller.send(name.to_s+"_generator", options)
      end

      # Create a widget for testing
      #
      # A page and a block are created on-the-fly, so there is no need to create
      # fixtures for each widget
      #
      def insert_widget_in_page(type, widget_options)
        widget_options.reverse_merge!(:name => 'TestWidget')
        widget, page = create_test_page(type, widget_options)
        assert widget.save, "Widget has errors (attributes: #{widget.options.inspect})"
        page.reload && page.publish
        [widget, page]
      end

      def create_test_page(type, widget_options)
        widget = type.to_s.classify.constantize.new(widget_options)
        block = Block.new(:block_type => 'test')

        default_page_options = {
          :name => 'Test page',
          :url_name => rand.to_s[2..-1],
          :page_template => 'test',
          :published_id => nil,
        }
        page = Page.create!(default_page_options)
        widget.block = block
        page.blocks << block
        [widget, page]
      end
    end
  end
end
