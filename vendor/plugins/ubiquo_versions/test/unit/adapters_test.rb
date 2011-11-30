require File.dirname(__FILE__) + "/../test_helper.rb"

class UbiquoVersions::AdaptersTest < ActiveSupport::TestCase
  
  def test_create_versionable_table
    definition = nil
    ActiveRecord::Base.connection.create_table(:test, :versionable => true, :force => true){|table| definition=table}
    ActiveRecord::Base.connection.drop_table(:test)
    assert_not_nil definition[:version_number]
    assert_not_nil definition[:is_current_version]
    assert_not_nil definition[:parent_version]
  end
  
  def test_dont_create_versionable_table
    definition = nil
    ActiveRecord::Base.connection.create_table(:test, :force => true){|table| definition=table}
    ActiveRecord::Base.connection.drop_table(:test)
    assert_nil definition[:version_number]
    assert_nil definition[:is_current_version]
    assert_nil definition[:parent_version]
  end
  
  def test_create_content_id_on_versionable_table
    definition = nil
    ActiveRecord::Base.connection.create_table(:test, :versionable => true, :force => true){|table| definition=table}
    ActiveRecord::Base.connection.drop_table(:test)
    assert_not_nil definition[:content_id]
  end
  
  def test_change_table_with_versionable
    connection = ActiveRecord::Base.connection
    connection.create_table(:test, :force => true){}
    connection.change_table(:test, :versionable => true){}
    column_names = connection.columns('test').map(&:name).map(&:to_s)
    
    assert column_names.include?('content_id')
    assert column_names.include?('version_number')
    assert column_names.include?('parent_version')
    assert column_names.include?('is_current_version')
    assert_equal 2, connection.list_sequences("test_$").size
    connection.drop_table(:test)
  end

  def test_change_table_with_versionable_false_should_delete_fields
    connection = ActiveRecord::Base.connection
    connection.create_table(:test, :force => true){}
    connection.change_table(:test, :versionable => true){}
    connection.change_table(:test, :versionable => false){}
    column_names = connection.columns('test').map(&:name).map(&:to_s)

    assert !column_names.include?('content_id')
    assert !column_names.include?('version_number')
    assert !column_names.include?('parent_version')
    assert !column_names.include?('is_current_version')
    assert_equal 0, connection.list_sequences("test_$").size

    connection.drop_table(:test)
  end

  def test_change_table_without_versionable_should_do_nothing
    connection = ActiveRecord::Base.connection
    connection.create_table(:test, :force => true){}
    connection.change_table(:test){}
    column_names = connection.columns('test').map(&:name).map(&:to_s)

    assert !column_names.include?('content_id')
    assert !column_names.include?('version_number')
    assert !column_names.include?('parent_version')
    assert !column_names.include?('is_current_version')
    assert_equal 0, connection.list_sequences("test_$").size

    connection.drop_table(:test)
  end
end
