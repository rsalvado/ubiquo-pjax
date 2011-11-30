require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::DesignsHelperTest < ActionView::TestCase
  include Ubiquo::Extensions::ConfigCaller

  test 'widget_tabs should get groups when mode is auto and there are groups' do
    @page = pages(:one)
    Widget.expects(:groups).at_least(1).returns({"subheader"=>[:free, :static_section, :global]})    
    Ubiquo::Config.context(:ubiquo_design).set(:widget_tabs_mode, :auto)
    assert_equal Widget.groups, widget_tabs
  end

  test 'widget_tabs should get blocks when mode is auto and there are no groups' do
    @page = pages(:one)
    Widget.expects(:groups).returns({})
    Ubiquo::Config.context(:ubiquo_design).set(:widget_tabs_mode, :auto)
    assert_equal @page.available_widgets_per_block, widget_tabs
  end

  test 'widget_tabs should get groups when mode is groups' do
    Ubiquo::Config.context(:ubiquo_design).set(:widget_tabs_mode, :groups)
    assert_equal Widget.groups, widget_tabs
  end

  test 'widget_tabs should get blocks when mode is blocks' do
    @page = pages(:one)
    Ubiquo::Config.context(:ubiquo_design).set(:widget_tabs_mode, :blocks)
    assert_equal @page.available_widgets_per_block, widget_tabs
  end

  test 'widget_tabs should call the config on other cases' do
    Ubiquo::Config.context(:ubiquo_design).set(
      :widget_tabs_mode,
      lambda{'value'}
    )
    assert_equal 'value', widget_tabs
  end

end
