require File.dirname(__FILE__) + "/../test_helper.rb"

class RolePermissionTest < ActiveSupport::TestCase
  use_ubiquo_fixtures

  def test_should_create_role_permission
    assert_difference 'RolePermission.count' do
      rp = create_role_permission
      assert !rp.new_record?, "#{rp.errors.full_messages.to_sentence}"
    end
  end

  def test_should_add_permission
    r=roles(:role_1)
    p=permissions(:permission_1)
    assert !r.has_permission?(p)
    assert_difference "r.permissions.reload.count" do
      assert r.add_permission(p)
    end
    assert r.has_permission?(p)
  end


  def test_shouldnt_add_duplicated_permission
    r=roles(:role_1)
    p=permissions(:permission_1)
    assert !r.has_permission?(p)
    assert r.add_permission(p)
    assert r.has_permission?(p)
    assert_no_difference "r.permissions.reload.count" do
      assert r.has_permission?(p)
    end
    assert r.has_permission?(p)
  end

  def test_should_remove_permission
    r=roles(:role_1)
    p=permissions(:permission_1)
    assert !r.has_permission?(p)
    assert r.add_permission(p)
    assert r.has_permission?(p)
    assert_difference "r.permissions.reload.count", -1 do
      assert r.remove_permission(p)
    end
    assert !r.has_permission?(p)
  end

  protected
  def create_role_permission(options = {})
    RolePermission.create({ :role => Role.find(:first, :offset=>1), :permission=>Permission.find(:first) }.merge(options))
  end

end
