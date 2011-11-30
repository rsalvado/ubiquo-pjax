require File.dirname(__FILE__) + "/../../../../../../test/test_helper.rb"

module Connectors
  class I18nTest < ActiveSupport::TestCase

    if Ubiquo::Plugin.registered[:ubiquo_i18n]

      def setup
        save_current_design_connector
        UbiquoDesign::Connectors::I18n.load!
        Locale.current = 'test'
      end

      def teardown
        reload_old_design_connector
        Locale.current = nil
      end

      test "widgets are translatable" do
        assert Widget.is_translatable?
      end

      test "create widgets migration" do
        ActiveRecord::Migration.expects(:create_table).with(:widgets, :translatable => true).once
        ActiveRecord::Migration.uhook_create_widgets_table
      end

      test "publication must copy widget translations and their asset relations" do
        page = create_page
        page.blocks << pages(:one).blocks
        assert_equal page.is_the_published?, false
        assert_raise ActiveRecord::RecordNotFound do
          Page.published.with_url(page.url_name)
        end
        widgets = page.blocks.map(&:widgets).flatten
        num_widgets = widgets.size
        assert num_widgets > 1
        general_locale = Locale.current
        widgets.each_with_index do |widget, i|
          widget.content_id = Widget.connection.next_val_sequence("#{Widget.table_name}_$_content_id")
          Locale.current = widget.locale = "loc#{i}"
          assert widget.save
        end
        assert_difference "Widget.count",num_widgets do # cloned widgets
          Locale.current = general_locale
          assert page.publish
        end
      end

      test "add_widget should not duplicate a widget if Locale.current its not the same of the widget" do
        begin
          locale = Locale.current
          Locale.current = 'en'

          page = create_page
          static_section = StaticSection.new(:name => "Sección en español",
            :title => "esto es una sección en español",
            :locale => "es_ES",
            :body => "")

          page.add_widget(:main, static_section)
          created_widgets = page.blocks.map{|i| i.widgets}.flatten
          assert_equal 1, created_widgets.size
        ensure
          Locale.current = locale
        end
      end

      test "publication must copy widget translations and all their relations" do
        create_free_widget_relations
        page = create_page
        widget = Free.create(
          :name => "Test Widget",
          :content => "Test widget with relations")
        page.blocks.first.widgets << widget
        # relate with simple has_many
        3.times do |i|
          widget.relation_examples.build(:name => "Example #{i}")
        end
        # relate with has_many :through
        widget.pages << [pages(:one), pages(:two)]
        widget.save
        assert_difference "Widget.count", 1 do
          assert_difference "RelationExample.count", widget.relation_examples.size do
            assert_difference "RelationThroughExample.count", 2 do
              assert page.publish
            end
          end
        end
        # cleanup
        Object.send :remove_const, "Free"
        load Rails.root.join("app","models","widgets","free.rb").to_s
      end

      test "widget_controller must set locale on the prepare widget with configurable widget" do
        widget = widgets(:one)
        widget.expects(:is_configurable?).returns(true)
        Ubiquo::WidgetsController.any_instance.stubs(
          :session => {:locale => 'es'},
          :params => {}
        )
        assert_not_equal 'es', widget.locale
        Ubiquo::WidgetsController.new.uhook_prepare_widget(widget)
        assert_equal 'es', widget.locale
      end

      test "widget_controller must set locale on the prepare widget with non configurable widget" do
        widget = widgets(:one)
        widget.expects(:is_configurable?).returns(false)
        Ubiquo::WidgetsController.any_instance.stubs(
          :session => {:locale => 'es'},
          :params => {}
        )
        assert_not_equal 'es', widget.locale
        Ubiquo::WidgetsController.new.uhook_prepare_widget(widget)
        assert_equal 'any', widget.locale
      end
    end

    test "show create two widgets for each locale"  do
      assert_difference "StaticSection.count", 2 do
        widget, page = create_widget(:static_section, :locale => "es_ES")
      end
    end

    private

    def widget_attributes
      {
        :title => 'About us (test company)',
      }
    end

    def create_widget(type, options = {})
      insert_widget_in_page(type, widget_attributes.merge(options))
    end

    def create_page(options = {})
      Page.create({
        :name => "Custom page",
        :url_name => "custom_page",
        :page_template => "static",
        :published_id => nil,
      }.merge(options))
    end

    def save_current_design_connector
      @old_connector = UbiquoDesign::Connectors::Base.current_connector
    end

    def reload_old_design_connector
      @old_connector.load!
    end

    def create_free_widget_relations
      Free.class_eval do
        has_many :relation_examples, :foreign_key => 'widget_id'
        has_many :relation_through_examples, :foreign_key => 'widget_id'
        has_many :pages, :through => :relation_through_examples
      end

      %w{ relation_examples relation_through_examples }.each do |table|
        if ActiveRecord::Base.connection.tables.include?(table)
          ActiveRecord::Base.connection.drop_table(table)
        end
      end

      ActiveRecord::Base.connection.create_table :relation_examples do |t|
        t.string  :name
        t.integer :widget_id
      end
  
      ActiveRecord::Base.connection.create_table :relation_through_examples do |t|
        t.integer :page_id
        t.integer :widget_id
      end
      if ::ActiveRecord::Base.connection.class.included_modules.include?(Ubiquo::Adapters::Mysql)
        # "Supporting" DDL transactions for mysql
        ::ActiveRecord::Base.connection.begin_db_transaction
        ::ActiveRecord::Base.connection.create_savepoint
      end      
    end

  end
end
class RelationExample < ActiveRecord::Base
  belongs_to :widget, :foreign_key => 'widget_id'
end

class RelationThroughExample < ActiveRecord::Base
  belongs_to :widget, :foreign_key => 'widget_id'
  belongs_to :page
end
