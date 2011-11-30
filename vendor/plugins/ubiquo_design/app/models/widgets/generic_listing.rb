class GenericListing < Widget
  self.allowed_options = [:model, :title, :per_page, :show_images]
  validates_presence_of :model

  # Returns the scope of elements to be shown.
  # If the model of the generic listing has a +generic_listing_elements+ method,
  # this method will take precedence.
  def elements
    model = self.model.constantize
    model.respond_to?(:generic_listing_elements) ? model.generic_listing_elements : model.all
  end
end
