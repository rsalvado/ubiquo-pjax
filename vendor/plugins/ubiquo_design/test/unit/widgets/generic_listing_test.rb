require File.dirname(__FILE__) + '/../../test_helper'

class GenericListingTest < ActiveSupport::TestCase
  
  test "should create generic_listing" do
    assert_difference 'GenericListing.count' do
      generic_listing = create_generic_listing
      assert !generic_listing.new_record?, "#{generic_listing.errors.full_messages.to_sentence}"
    end
  end

  test "elements method should call first to generic_listing_elements" do
    generic_listing = create_generic_listing
    GenericListing.expects(:generic_listing_elements).returns(
      GenericListing.scoped(:conditions => {:name => 'non_existing'})
    )
    assert_equal [], generic_listing.elements
  end

  test "elements method should call to all if generic method not present" do
    generic_listing = create_generic_listing
    assert_equal GenericListing.all, generic_listing.elements
  end

  private
  
  def create_generic_listing(options = {})
    default_options = {
      :name => "Test generic_listing", 
      :block => blocks(:one),
      :model => GenericListing.to_s,
      :title => 'Generic listing',
      :per_page => '5',
      :show_images => true
    }
    GenericListing.create(default_options.merge(options))
  end
end
