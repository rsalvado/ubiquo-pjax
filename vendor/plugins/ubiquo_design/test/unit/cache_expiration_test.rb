require File.dirname(__FILE__) + "/../test_helper.rb"

class UbiquoDesign::CacheExpirationTest < ActiveSupport::TestCase
  use_ubiquo_fixtures

  # load these independently of the perform_caching flag to correctly test their effects
  unless ActionController::Base.included_modules.include? UbiquoDesign::CacheRendering
    ActionController::Base.send(:include, UbiquoDesign::CacheRendering)
  end
  unless ActiveRecord::Base.included_modules.include? UbiquoDesign::CacheExpiration::ActiveRecord
    ActiveRecord::Base.send(:include, UbiquoDesign::CacheExpiration::ActiveRecord)
  end
  
  def setup
    @manager = UbiquoDesign.cache_manager
  end

  def teardown
    UbiquoDesign::CachePolicies.clear(:test)
  end

  test 'should_expire_widget_on_model_update' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => 'Page'
      }
    end
    widget = widgets(:one)
    @manager.cache(widget, 'content', caching_options)
    assert @manager.get(widget, caching_options)
    page = pages(:one)
    page.instance_variable_set(:@cache_policy_context, :test)
    page.save
    widget.reload
    assert !@manager.get(widget, caching_options)
  end

  test 'should_expire_widget_on_model_creation' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => 'Free'
      }
    end
    widget = widgets(:one)
    @manager.cache(widget, 'content', caching_options)
    assert @manager.get(widget, caching_options)
    new = Free.new(:name => 'free', :block => blocks(:one), :content => 'test')
    new.instance_variable_set(:@cache_policy_context, :test)
    new.save
    widget.reload
    assert !@manager.get(widget, caching_options)
  end

  test 'should_expire_correct_widgets_on_model_instance_update' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => [{'Page' => {:id => :id}}]
      }
    end
    widget = widgets(:one)
    page = pages(:one)
    page.instance_variable_set(:@cache_policy_context, :test)
    @manager.cache(widget, 'content', caching_options(page.id))
    @manager.cache(widget, 'content', caching_options('other'))
    assert @manager.get(widget, caching_options(page.id))
    assert @manager.get(widget, caching_options('other'))
    page.save
    assert !@manager.get(widget, caching_options(page.id))
    assert @manager.get(widget, caching_options('other'))
  end


  test 'should_expire_correct_widgets_on_different_model_instance_updates' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => [{'Page' => {:id => :id}}, 'Free']
      }
    end
    free_widget = Free.first
    widget = widgets(:one)
    page = pages(:one)
    page.instance_variable_set(:@cache_policy_context, :test)
    free_widget.instance_variable_set(:@cache_policy_context, :test)

    @manager.cache(widget, 'content', caching_options(page.id))
    @manager.cache(widget, 'content', caching_options('other'))
    
    assert @manager.get(widget, caching_options(page.id))
    assert @manager.get(widget, caching_options('other'))
    page.save
    assert !@manager.get(widget, caching_options(page.id))
    assert @manager.get(widget, caching_options('other'))
    
    @manager.cache(widget, 'content', caching_options(page.id))
    assert @manager.get(widget, caching_options(page.id))

    free_widget.save
    widget.reload
    assert !@manager.get(widget, caching_options(page.id))
    assert !@manager.get(widget, caching_options('other'))  
  end

  test 'should_be_expired_when_parent_key_is_not_present' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => [{'Page' => {:id => :id}}, 'Free']
      }
    end
    free_widget = Free.first
    widget = widgets(:one)
    page = pages(:one)
    page.instance_variable_set(:@cache_policy_context, :test)
    free_widget.instance_variable_set(:@cache_policy_context, :test)

    @manager.cache(widget, 'content', caching_options(page.id))
    assert @manager.get(widget, caching_options(page.id))
    parents = []
    @manager.send('with_instance_content', widget, caching_options(page.id)) do |i_key|
      parents << i_key
    end
    @manager.send('delete', parents.first)
    assert !@manager.get(widget, caching_options(page.id))
  end
  
  test 'should_expire_correct_widgets_on_different_model_instance_updates_with_proc_mapping' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => [{'Page' => { :id => lambda{one}}}, 'Free']
      }
    end
    free_widget = Free.first
    widget = widgets(:one)
    page = pages(:one)
    page.instance_variable_set(:@cache_policy_context, :test)
    free_widget.instance_variable_set(:@cache_policy_context, :test)

    @manager.cache(widget, 'content', caching_options('aa', page.id))
    @manager.cache(widget, 'content', caching_options('aa', 'other'))
    
    assert @manager.get(widget, caching_options('aa', page.id))
    assert @manager.get(widget, caching_options('aa', 'other'))
    page.save
    assert !@manager.get(widget, caching_options('aa', page.id))
    assert @manager.get(widget, caching_options('aa', 'other'))

    @manager.cache(widget, 'content', caching_options('aa', page.id))
    assert @manager.get(widget, caching_options('aa', page.id))

    free_widget.save
    widget.reload
    assert !@manager.get(widget, caching_options('aa', page.id))
    assert !@manager.get(widget, caching_options('aa', 'other'))  
  end

  test 'should_expire_correct_widgets_on_different_model_instance_destroys' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => [{'Page' => {:id => :id}}]
      }
    end
    widget = widgets(:one)
    page = pages(:one)
    page.instance_variable_set(:@cache_policy_context, :test)
    widget.instance_variable_set(:@cache_policy_context, :test)
    @manager.cache(widget, 'content', caching_options(page.id))
    @manager.cache(widget, 'content', caching_options('other'))
    assert @manager.get(widget, caching_options(page.id))
    assert @manager.get(widget, caching_options('other'))

    page.destroy
    assert !@manager.get(widget, caching_options(page.id))
    assert @manager.get(widget, caching_options('other'))  
  end

  test 'should_expire_by_time' do
    UbiquoDesign::CachePolicies.define(:test) do
      {
        :free => [{'Page' => {:id => :id}}, {:expires_in => 3.seconds}]
      }
    end
    widget = widgets(:one)
    page = pages(:one)
    page.instance_variable_set(:@cache_policy_context, :test)
    widget.instance_variable_set(:@cache_policy_context, :test)

    assert_equal @manager.send('get_expiration_time',widget, caching_options(page.id)), 3
  end
  
  protected

  def create_widget
    Free.create(:name => 'free', :block => blocks(:one), :content => 'test')
  end

  def caching_options(id = 'test', one = 'one')
    {
      :scope => OpenStruct.new(:params => {:id => id}, :one => one),
      :policy_context => :test
    }
  end

end
