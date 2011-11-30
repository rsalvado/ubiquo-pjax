require File.dirname(__FILE__) + "/../../test_helper.rb"

class UbiquoDesign::CacheManagers::MemcacheTest < ActiveSupport::TestCase

  def setup
    @manager = UbiquoDesign::CacheManagers::Memcache
  end

  test 'store should set to memcache' do
    connection = mock()
    connection.expects(:set).with(@manager.send('crypted_key', 'id'), 'content', 2.seconds)
    @manager.stubs(:connection).returns(connection)
    @manager.send :store, 'id', 'content', 2.seconds
  end

  test 'retrieve should get from memcache' do
    connection = mock()
    connection.expects(:get).with(@manager.send('crypted_key', 'id'))
    @manager.stubs(:connection).returns(connection)
    @manager.send :retrieve, 'id'
  end

  test 'delete should delete from memcache' do
    connection = mock()
    connection.expects(:delete).with(@manager.send('crypted_key', 'id'))
    @manager.stubs(:connection).returns(connection)
    @manager.send :delete, 'id'
  end

  test 'connection should raise when the server is not available' do
    if UbiquoDesign::CacheManagers::Memcache.instance_variable_get("@cache")
      UbiquoDesign::CacheManagers::Memcache.instance_variable_set("@cache","")
    end
    assert_raise UbiquoDesign::CacheManagers::Memcache::MemcacheNotAvailable do
      Ubiquo::Config.context(:ubiquo_design).get(:memcache).merge!(:server => "")
      @manager.send(:connection)
    end
    assert_raise UbiquoDesign::CacheManagers::Memcache::MemcacheNotAvailable do
      Ubiquo::Config.context(:ubiquo_design).get(:memcache).merge!(:server => "1985")
      @manager.send(:connection)
     end
  end

  test 'connection should open only one connection with memcached' do
    @manager.instance_variable_set("@cache", mock())
    MemCache.expects(:new).never
    2.times { @manager.send(:connection) }
  end

  test 'multi_retrieve should multi_get from memcache' do
    connection = mock()
    content_ids = ['id_one', 'id_two']
    connection.expects(:get_multi).with(content_ids)
    @manager.stubs(:connection).returns(connection)
    @manager.send :multi_retrieve, content_ids
  end

end
