require File.dirname(__FILE__) + "/../test_helper.rb"

class PermissionTest < ActiveSupport::TestCase
  use_ubiquo_fixtures

  def test_should_create_permission
    assert_difference 'Permission.count' do
      permission = create_permission
      assert !permission.new_record?, "#{permission.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_name
    assert_no_difference 'Permission.count' do
      permission = create_permission :name=>nil
      assert permission.errors.on(:name)
    end
  end


  def test_should_require_key
    assert_no_difference 'Permission.count' do
      permission = create_permission :key=>nil
      assert permission.errors.on(:key)
    end
  end

  def test_should_require_unique_key
    assert_difference 'Permission.count', 1 do
      permission = create_permission :key=> 'my_key'
      permission = create_permission :key=> permission.key
      assert permission.errors.on(:key)
      permission = create_permission :key=> permission.key.upcase
      assert permission.errors.on(:key)
    end
  end

  def test_should_require_valid_key
    assert_no_difference 'Permission.count' do
      permission = create_permission :key=>"NotAValidKey"
      assert permission.errors.on(:key)
      permission = create_permission :key=>"not-a-valid-key"
      assert permission.errors.on(:key)
      permission = create_permission :key=>"not a valid key"
      assert permission.errors.on(:key)
      permission = create_permission :key=>"not.a.valid.key"
      assert permission.errors.on(:key)
    end
  end

  private
  def create_permission(options = {})
    Permission.create({:name=>"Created Permission", :key=>"created_permission"}.merge(options))
  end
end
