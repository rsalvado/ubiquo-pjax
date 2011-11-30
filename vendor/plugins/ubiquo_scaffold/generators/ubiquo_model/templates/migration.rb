class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    create_table :<%= table_name %><%= options[:versionable] ? ", :versionable => true" : "" -%><%= options[:translatable] ? ", :translatable => true" : "" -%> do |t|
<% for attribute in attributes -%>
      t.<%= attribute.type %> :<%= attribute.name %>
<% end -%>
<% if options[:belongs_to] -%>
  <%- options[:belongs_to].each do |bt| -%>
    <%- belongs_to_field = "#{bt.singularize}_id" -%>
    <%- unless attributes.include? belongs_to_field -%>
      t.integer :<%= belongs_to_field %>
    <%- end -%>
  <%- end -%>
<% end -%>
<% unless options[:skip_timestamps] %>
      t.timestamps
<% end -%>
    end
<%- if options[:categorized] -%>
<%- options[:categorized].each do |categorized| -%>
<%- category_set_key = categorized.pluralize -%>
    unless CategorySet.find_by_key(<%= category_set_key.to_json %>)
      CategorySet.create(:key => <%= category_set_key.to_json %>, :name => <%= category_set_key.humanize.to_json %>)
    end
<% end -%>
<% end -%>
<% if options[:has_many] -%>
  <%- options[:has_many].each do |hm| -%>
    <%- target_class = "#{hm.classify}" -%>
    <%- belongs_to_field = "#{table_name.singularize}_id" -%>
    if defined?(<%= target_class %>) && <%= target_class %>.table_exists?
      <%= target_class %>.reset_column_information
      unless <%= target_class %>.column_names.include?(<%= belongs_to_field.to_json %>)
        add_column <%= target_class%>.table_name, :<%= belongs_to_field %>, :integer
      end
    end
  <%- end -%>
<% end -%>
  end

  def self.down
    drop_table :<%= table_name %>
  end
end
