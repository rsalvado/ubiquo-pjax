require File.dirname(__FILE__) + "/../test_helper.rb"

class UbiquoI18n::AdaptersTest < ActiveSupport::TestCase

  def test_create_i18n_table
    definition = nil
    ActiveRecord::Base.silence{
      ActiveRecord::Base.connection.create_table(:test, :translatable => true, :force => true){|table| definition=table}
    }
    ActiveRecord::Base.connection.drop_table(:test)
    assert_not_nil definition[:locale]
  end

  def test_dont_create_i18n_table
    definition = nil
    ActiveRecord::Base.silence{
      ActiveRecord::Base.connection.create_table(:test, :force => true){|table| definition=table}
    }
    ActiveRecord::Base.connection.drop_table(:test)
    assert_nil definition[:locale]
  end

  def test_create_content_id_on_i18n_table
    definition = nil
    ActiveRecord::Base.silence{
      ActiveRecord::Base.connection.create_table(:test, :translatable => true, :force => true){|table| definition=table}
    }
    ActiveRecord::Base.connection.drop_table(:test)
    assert_not_nil definition[:content_id]
  end

  def test_change_table_with_translatable
    connection = ActiveRecord::Base.connection
    ActiveRecord::Base.silence{
      connection.create_table(:test, :force => true){}
      connection.change_table(:test, :translatable => true){}
    }
    column_names = connection.columns('test').map(&:name).map(&:to_s)
    assert column_names.include?('content_id')
    assert column_names.include?('locale')
    assert_equal 1, connection.list_sequences("test_$").size
    connection.drop_table(:test)
  end

  def test_change_table_with_translatable_should_fill_i18n_fields
    connection = ActiveRecord::Base.connection

    # create a test table and model for our purposes
    connection.create_table(:test_i18n_fields, :force => true) {|t| t.timestamps}
    Object.const_set 'TestI18nField', Class.new(ActiveRecord::Base)

    # create an instance now to see how its fields will be filled
    if ::ActiveRecord::Base.connection.class.included_modules.include?(Ubiquo::Adapters::Mysql)
      # "Supporting" DDL transactions for mysql
      ::ActiveRecord::Base.connection.begin_db_transaction
      ::ActiveRecord::Base.connection.create_savepoint
    end
    TestI18nField.create

    # now convert the table into i18n
    connection.change_table(:test_i18n_fields, :translatable => true, :locale => 'jp') {}
    TestI18nField.reset_column_information

    # assert that the fields have been filled
    existing = TestI18nField.first
    assert_equal 'jp', existing.locale
    assert_equal existing.id, existing.content_id

    # now test the method without a locale option (should use Locale.default)
    connection.change_table(:test_i18n_fields, :translatable => false) {}
    connection.change_table(:test_i18n_fields, :translatable => true ) {}
    assert_equal Locale.default, TestI18nField.first.locale

    # cleanup
    connection.drop_table(:test_i18n_fields)
    Object.send :remove_const, 'TestI18nField'
  end

  def test_change_table_with_translatable_false_should_delete_fields
    connection = ActiveRecord::Base.connection
    ActiveRecord::Base.silence{
      connection.create_table(:test, :force => true){}
      connection.change_table(:test, :translatable => true){}
      connection.change_table(:test, :translatable => false){}
    }
    column_names = connection.columns('test').map(&:name).map(&:to_s)
    assert !column_names.include?('content_id')
    assert !column_names.include?('locale')
    assert_equal 0, connection.list_sequences("test_$").size
    connection.drop_table(:test)
  end

  def test_change_table_without_translatable_should_do_nothing
    connection = ActiveRecord::Base.connection
    ActiveRecord::Base.silence{
      connection.create_table(:test, :force => true){}
      connection.change_table(:test){}
    }
    column_names = connection.columns('test').map(&:name).map(&:to_s)
    assert !column_names.include?('content_id')
    assert !column_names.include?('locale')
    assert_equal 0, connection.list_sequences("test_$").size
    connection.drop_table(:test)
  end

end
