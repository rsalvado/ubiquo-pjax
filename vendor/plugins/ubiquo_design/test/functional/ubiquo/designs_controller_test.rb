require File.dirname(__FILE__) + "/../../test_helper.rb"

class Ubiquo::DesignsControllerTest < ActionController::TestCase
  use_ubiquo_fixtures
  
  def test_should_get_design
    login_as
    page = pages(:one_design)
    template_mock(page)
    get :show, :page_id => page.id
    assert_response :success
    assert_not_nil page = assigns(:page)
    assert page.blocks.size > 0
    page.blocks.map(&:block_type).each do |block_type|
      assert_select "#block_type_holder_#{block_type}"
      # TODO: We going to change default blocks way.
      # We need check over this when we changed it.
      block = page.blocks.first(:conditions => { :block_type => block_type })
      #
      last_order = 0
      block.widgets.each do |widget|
        assert_operator widget.position, :>, last_order
        last_order = widget.position
      
        assert_select "#widget_#{widget.id}"
      end
    end
  end

  def test_should_get_design_with_permission
    login_with_permission :design_management
    page = pages(:one_design)
    template_mock(page)
    get :show, :page_id => page.id
    assert_response :success
  end

  def test_should_not_get_design_without_permission
    login_with_permission 
    get :show, :page_id => pages(:one_design).id
    assert_response :forbidden
  end

  def test_should_show_edit_widget_with_editable_widgets
    login_as
    widget = nil
    assert_nothing_thrown do
      widget = widgets(:one)
      page = widget.block.page
      assert_not_nil page
    end

    page = pages(:one_design)
    template_mock(page)    
    get :show, :page_id => page.id

    assert_select "#widget_#{widget.id} .editar", false
  end

  def test_should_preview_page_if_its_previewable
    login_as
    page = pages(:one_design)
    widget = GenericListing.new(
      :name => "Test widget",
      :title => "Test widget title",
      :model => "GenericListing")
    page.add_widget(:main, widget)
    page.save
    get :preview, :page_id => page.id
    assert_select "div.genericlisting-list.generic-main-list" do
      assert_select 'h3', 'Test widget title'
    end
  end

  def test_should_preview_page_with_required_params
    login_as
    page = pages(:one_design)
    widget = GenericDetail.new(
      :name => "Test widget",
      :model => "GenericDetail")
    page.add_widget(:main, widget)
    page.save
    GenericDetail.any_instance.expects(:element).returns(GenericDetail.first)
    get :preview, :page_id => page.id
    assert_select "div.genericdetail-detail.generic-detail" do
      assert_select 'h3', "Test widget"
      assert_select 'div.content'
    end
  end

  def test_should_preview_unpreviewable_page
    login_as
    page = pages(:one_design)
    Free.send(:previewable, false)
    Free.create(
      :name => "Test widget",
      :block_id => page.blocks.first.id,
      :content => "test content")
    page.save
    assert_raise Ubiquo::DesignsController::UnpreviewablePage do
      get :preview, :page_id => page.id
    end
  end

  def test_should_get_design_with_blocks_and_subblocks
    UbiquoDesign::Structure.define do
      page_template :with_subblocks do 
      block :independent, :cols => 2
      block :group, :cols => 2 do
        subblock :s1, :cols => 1
        subblock :s2, :cols => 1
        end
      end
    end
    page = Page.create(
      :name => "Test page",
      :url_name => "test",
      :page_template => "with_subblocks")

    get :show, :page_id => page.id
    assert_response :success
    assert_select "div.column", 2
    assert_select "div.column div.column", 2 #subblocks
  end
  
end
