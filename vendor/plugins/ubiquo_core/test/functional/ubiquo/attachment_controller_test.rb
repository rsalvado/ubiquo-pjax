require File.dirname(__FILE__) + "/../../test_helper.rb"
class Ubiquo::AttachmentControllerTest < ActionController::TestCase

  def setup
    # We setup tmp as private_path to avoid errors when the real
    # directory doesn't exit.
    @private_path = Ubiquo::Config.get(:attachments)[:private_path]
    @tmp_path = 'tmp'
    Ubiquo::Config.get(:attachments)[:private_path] = @tmp_path
  end

  def teardown
    Ubiquo::Config.get(:attachments)[:private_path] = @private_path
  end
  
  def test_should_not_be_able_to_request_attachments_outside_the_private_path
    assert_raises ActiveRecord::RecordNotFound do
      get(:show, { :path => '../config/routes.rb'})
    end
  end
  
  def test_should_be_able_to_obtain_attachments_inside_private_path_when_logged_in
    dummy_file = Tempfile.new('dummy', Rails.root.join(@tmp_path))
    dummy_file.flush
    get(:show, { :path => File.basename(dummy_file.path) })
    assert_response :success
  end
  
  def test_should_not_be_able_to_obtain_attachment_when_not_logged_in
    session[:ubiquo] ||= {}
    session[:ubiquo][:ubiquo_user_id] = nil
    get(:show, { :path => 'dummy' })
    assert_redirected_to :ubiquo_login
  end
end
