class <%= class_name %> < ActiveRecord::Base
  <%- if options[:versionable] -%>
  versionable <%= options[:versions_amount] ? " :max_amount => #{options[:versions_amount]}" : "" %>

  <%- end -%>
  <%- if options[:translatable] -%>
  translatable <%= options[:translatable].map{|i| ":#{i}"}.join(", ") %>

  <%- end -%>
  <%- if options[:has_many] -%>
    <%- options[:has_many].each do |rl| -%>
  has_many :<%= rl.pluralize %>
    <%- end -%>
  <%- end -%>
  <%- if options[:belongs_to] -%>
    <%- options[:belongs_to].each do |rl| -%>
  belongs_to :<%= rl.singularize %>
    <%- end -%>
  <%- end -%>
  <%- if options[:media] -%>

    <%- options[:media].each do |rl| -%>
  media_attachment :<%= rl %>, :types => %w{image doc video audio flash}
    <%- end -%>
  <%- end -%>
  <%- if options[:categorized] -%>

    <%- options[:categorized].each do |rl| -%>
  categorized_with :<%= rl %>
    <%- end -%>
  <%- end -%>
  <%- unless ton.nil? -%>

  validates_presence_of :<%= ton %>
  <%- end -%>

  filtered_search_scopes

end
