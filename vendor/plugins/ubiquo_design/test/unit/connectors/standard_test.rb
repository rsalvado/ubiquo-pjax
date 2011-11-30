require File.dirname(__FILE__) + "/../../../../../../test/test_helper.rb"

module Connectors
  class StandardTest < ActiveSupport::TestCase
    def setup
      UbiquoDesign::Connectors::Standard.load!
    end

    test "should publish widgets" do
      page = create_page
      page.blocks << pages(:one).blocks
      assert page.is_modified?
      assert !page.is_the_published?
      assert_nil Page.published.find_by_url_name(page.url_name)
      num_widgets = page.blocks.map(&:widgets).flatten.size
      assert num_widgets > 0
      assert_difference "Widget.count", num_widgets do # cloned widgets
        assert page.publish
      end
    end

    test "should load public page" do
      p = pages(:one_design)
      PagesController.any_instance.stubs(:params => { :url => p.url_name })
      assert_equal pages(:one), PagesController.new.uhook_load_page
    end

    test "should not load nonpublic page" do
      p = pages(:unpublished)
      PagesController.any_instance.stubs(:params => { :url => p.url_name })
      assert_raise ActiveRecord::RecordNotFound do
        PagesController.new.uhook_load_page
      end
    end

    test "should load public page by key" do
      p = pages(:one_design)
      PagesController.any_instance.stubs(:params => { :key => p.key })
      assert_equal pages(:one), PagesController.new.uhook_load_page
    end

    test "should not load nonpublic page by key" do
      p = pages(:unpublished)
      PagesController.any_instance.stubs(:params => { :key => p.key})
      assert_raise ActiveRecord::RecordNotFound do
        PagesController.new.uhook_load_page
      end
    end

    test "widgets_controller find widget" do
      c = widgets(:one)
      Ubiquo::WidgetsController.any_instance.stubs(:params => {:id => c.id})
      assert_equal c, Ubiquo::WidgetsController.new.uhook_find_widget
    end

    test "widgets_controller destroy widget" do
      assert_difference "Widget.count", -1 do
        assert Ubiquo::WidgetsController.new.uhook_destroy_widget(widgets(:one))
      end
    end

    test "widgets_controller update widget" do
      c = widgets(:one)
      Ubiquo::WidgetsController.any_instance.stubs(:params => {:id => c.id, :widget => {:name => "test"}})
      assert_equal "test", Ubiquo::WidgetsController.new.uhook_update_widget.name
    end

    test "ubiquo pages_controller find pages" do
      searched_pages = Ubiquo::PagesController.new.uhook_find_private_pages({}, 'name', 'asc')
      fixture_pages = [pages(:one_design), pages(:two_design),
                       pages(:only_menu_design), pages(:test_page),
                       pages(:unpublished), pages(:long_url),
                      ].select{|page| page.is_the_draft?}
      assert_equal_set fixture_pages, searched_pages
    end

    test "ubiquo pages_controller new page" do
      assert Ubiquo::PagesController.new.uhook_new_page.new_record?
    end

    test "ubiquo pages_controller create page" do
      attributes = create_page.attributes
      attributes[:url_name] = "test"
      Ubiquo::PagesController.any_instance.stubs(:params => {:page => attributes})
      p = nil
      assert_difference "Page.count" do
        p = Ubiquo::PagesController.new.uhook_create_page
      end
      assert !p.new_record?, p.errors.full_messages.to_sentence
    end

    test "ubiquo pages_controller update page" do
      page = create_page
      attributes = page.attributes
      attributes[:name] = "test"
      Ubiquo::PagesController.any_instance.stubs(:params => {:page => attributes})
      Ubiquo::PagesController.new.uhook_update_page(page)
      assert_equal "test", page.reload.name
    end

    test "ubiquo pages_controller destroy page" do
      page = create_page
      assert_difference "Page.count", -1 do
        Ubiquo::PagesController.new.uhook_destroy_page(page)
      end
    end

    test "create page migration" do
      ActiveRecord::Migration.expects(:create_table).with(:pages).once
      ActiveRecord::Migration.uhook_create_pages_table
    end

    test "create widgets migration" do
      ActiveRecord::Migration.expects(:create_table).with(:widgets).once
      ActiveRecord::Migration.uhook_create_widgets_table
    end

    test "page returns return_static_section_widget" do
      Ubiquo::Config.context(:ubiquo_design).set(:block_type_for_static_section_widget, :main)
      page = create_page
      widget = StaticSection.create(:name => 'Test static', :title => 'Test')
      page.add_widget(:main, widget)
      assert_equal widget, page.uhook_static_section_widget
    end

    private

    def create_page(options = {})
      Page.create({
        :name => "Custom page",
        :url_name => "custom_page",
        :page_template => "static",
        :published_id => nil,
      }.merge(options))
    end
  end
end
