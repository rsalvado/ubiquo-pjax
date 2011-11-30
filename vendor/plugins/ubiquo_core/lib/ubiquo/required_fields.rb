
module Ubiquo

  #Usage:
  #Add 'required_fields' to your ActiveRecord model:
  # class YourModel < ActiveRecord::Base
  #   required_fields :name
  # end
  #
  #If you use 'validates_pressence_of' it will automaticaly detected as required field.
  #
  #Once a field is marked as required, it will show an asterisk(*) in field label inside the form
  #
  # <% form_for ... do |form|>
  #   <%= form.label :name, "Name" %>
  # <% end %>
  #
  #this label will be
  # <label for="yourmodel_name">Name *</label>
  #
  #
  #
  #This extension also provides an optional value for label_tag helper
  #named 'append_asterisk' that only appends an asterisk after the label content.
  #
  #
  #This asterisk can be manually disabled from view, just adding :append_asterisk => false to the helper options:
  # <%= form.label :name, "Name", :append_asterisk => false %>
  #
  #


  module RequiredFields
  end
end

ActiveRecord::Base.send :include, Ubiquo::RequiredFields::ActiveRecord
ActiveRecord::Validations::ClassMethods.send :include, Ubiquo::RequiredFields::Validations
ActionView::Helpers::FormHelper.send :include, Ubiquo::RequiredFields::FormHelper
ActionView::Helpers::FormTagHelper.send :include, Ubiquo::RequiredFields::FormTagHelper
