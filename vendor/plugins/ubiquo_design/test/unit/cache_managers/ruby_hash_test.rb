require File.dirname(__FILE__) + "/../../test_helper.rb"

class UbiquoDesign::CacheManagers::RubyHashTest < ActiveSupport::TestCase

  def setup
    @manager = UbiquoDesign::CacheManagers::RubyHash
  end

  test 'should store and retrieve' do
    @manager.send :store, 'id', 'content'
    assert_equal 'content', @manager.send(:retrieve, 'id')
  end

  test 'should delete from the hash' do
    @manager.send :store, 'id', 'content'
    @manager.send :delete, 'id'
    assert_nil @manager.send(:retrieve, 'id')
  end

  test 'should get by multi_retrieve' do
    ids = []; contents = []
    3.times do |i|
      ids[i] = "id_#{i}"
      contents[i] = "content_#{i}"
      @manager.send :store, ids[i], contents[i]
    end
    assert_equal Hash[*ids.zip(contents).flatten], @manager.send(:multi_retrieve, ids)
  end
end
