module Ubiquo::<%= controller_class_name %>Helper
  def <%= singular_name %>_filters
    filters_for "<%= model_name %>" do |f|
      f.text
      <%- if options[:translatable] -%>
      f.locale
      <%- end -%>
      <%- if has_published_at -%>
      f.date
      <%- end -%>
    end
  end

  def <%= singular_name %>_list(collection, pages, options = {})
    render(:partial => "shared/ubiquo/lists/standard", :locals => {
        :name => '<%= singular_name%>',
        :headers => [<%= attributes.collect{|at| ":#{at.name}"}.join(", ") %>],
        :rows => collection.collect do |<%= singular_name%>|
          {
            :id => <%= singular_name%>.id,
            :columns => [
              <%- attributes.each do |at| -%>
              <%= "#{singular_name}.#{at.name}," %>
              <%- end -%>
            ],
            :actions => <%= singular_name %>_actions(<%= singular_name%>)
          }
        end,
        :pages => pages,
        :link_to_new => link_to(t("ubiquo.<%= singular_name %>.index.new"),
                                new_ubiquo_<%= singular_name %>_path, :class => 'new')
      })
  end

  private

  def <%= singular_name %>_actions(<%= singular_name%>, options = {})
    actions = []
    <%- if options[:translatable] -%>
    if <%= singular_name%>.in_locale?(current_locale)
      actions << link_to(t("ubiquo.edit"), [:edit, :ubiquo, <%= singular_name%>], :class => 'btn-edit')
    end

    unless <%= singular_name%>.in_locale?(current_locale)
      actions << link_to(
        t("ubiquo.translate"),
        new_ubiquo_<%= singular_name%>_path(
          :from => <%= singular_name%>.content_id
          )
        )
    end

    actions << link_to(t("ubiquo.remove"),
      ubiquo_<%= singular_name%>_path(<%= singular_name%>, :destroy_content => true),
      :confirm => t("ubiquo.<%= singular_name %>.index.confirm_removal"), :method => :delete,
      :class => 'btn-delete'
      )

    if <%= singular_name%>.in_locale?(current_locale, :skip_any => true) && !<%= singular_name%>.translations.empty?
      actions << link_to(t("ubiquo.remove_translation"), [:ubiquo, <%= singular_name%>],
        :confirm => t("ubiquo.<%= singular_name %>.index.confirm_removal"), :method => :delete
        )
    end

    <%- else -%>
    actions << link_to(t("ubiquo.edit"), [:edit, :ubiquo, <%= singular_name%>], :class => 'btn-edit')
    actions << link_to(t("ubiquo.remove"), [:ubiquo, <%= singular_name%>],
      :confirm => t("ubiquo.<%= singular_name %>.index.confirm_removal"), :method => :delete, 
      :class => 'btn-delete'
      )
    <%- end -%>
    actions
  end
end
