class GenericHighlighted < Widget
  self.allowed_options = [:model, :title, :limit]

  validates_presence_of :model

  # Returns the scope of elements to be shown.
  # If the model of the generic highlighting has a +generic_highlighted_elements+ method,
  # this method will take precedence.
  def elements
    model = self.model.constantize
    model.respond_to?(:generic_highlighted_elements) ? model.generic_highlighted_elements(:limit => limit) : model.all(:limit => limit)
  end
end
