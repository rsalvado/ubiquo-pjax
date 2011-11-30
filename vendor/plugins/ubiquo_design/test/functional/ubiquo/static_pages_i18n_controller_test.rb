require File.dirname(__FILE__) + "/../../test_helper.rb"

# this test class is created to include i18n connector and make models
# translatable
class Ubiquo::StaticPagesI18nControllerTest < ActionController::TestCase
  use_ubiquo_fixtures

  if Ubiquo::Plugin.registered[:ubiquo_i18n]

    def setup
      save_current_connector(:ubiquo_design)
      UbiquoDesign::Connectors::I18n.load!
      login_as
    end

    def teardown
      reload_old_connector(:ubiquo_design)
      Locale.current = nil
    end

    def test_should_assign_the_same_content_id_to_widgets_of_same_page_when_translating
      @controller = Ubiquo::StaticPagesController.new

      page = Page.create(:name => "Start page",
        :page_template => "static",
        :is_static => true,
        :is_modified => false,
        :url_name => "test_url"
      )

      static_section = StaticSection.new(:name => "Sección en español",
        :title => "esto es una sección en español",
        :locale => "es_ES",
        :body => "")

      page.add_widget(:main, static_section)
      created_widgets = page.blocks.map{|i| i.widgets}.flatten
      assert_equal 1, created_widgets.size

      put(:update,
        :id => page.id,
        :from => created_widgets.first.content_id,
        :page => {
          :name => "Unique page identifier",
          :url_name => "custom_page",
          :page_template => "static"
        },
        :static_section => {
          :title => "English section",
          :body => "this is an english section",
          :locale => "en_US"
        },
        :locale =>"en_US" # we are browsing US locale
      )

      created_widgets = page.reload.blocks.map{|i| i.widgets}.flatten
      assert_equal 2, created_widgets.size

      # because is a translated widget, it should have the same content_id
      assert_equal created_widgets[0].content_id, created_widgets[1].content_id

    end

  end

end
