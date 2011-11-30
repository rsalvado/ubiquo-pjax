require File.dirname(__FILE__) + "/../test_helper.rb"

class UbiquoAccessControl::Extensions::HelperTest < ActionView::TestCase
  use_ubiquo_fixtures

  def test_user_permission_fields
    @roles = []
    form_mock = stub(:object => UbiquoUser.first)
    fields = user_permission_fields(form_mock)
    result = HTML::Document.new(fields)
    assert_select result.root, "input[type=hidden][name='ubiquo_user[role_ids][]']"
  end

end
