require 'ubiquo'

Ubiquo::Plugin.register(:ubiquo, directory, config)

Ubiquo::Config.add(:elements_per_page, 10)

Ubiquo::Config.add(:max_size_for_links_filter, 5)

# :model_groups is a hash :group_name => %w{table names in group}
Ubiquo::Config.add(:model_groups, {})
Ubiquo::Config.add(:attachments, {
  :visibility => :public,
  :public_path => "public",
  :private_path => "protected",
  :use_x_send_file => !Rails.env.development?,
})

Ubiquo::Config.add(:required_field_class, 'required_field')

Ubiquo::Config.add(:error_field_class, 'error_field')

Ubiquo::Config.add(:ubiquo_path, 'ubiquo')

Ubiquo::Config.add(:edit_on_row_click, true)

Ubiquo::Config.create_context(:ubiquo_form_builder)
Ubiquo::Config.context(:ubiquo_form_builder) do |context|
  context.add( :default_tag_options, {
    :text_area => { :class => "visual_editor" },
    :relation_selector => { :append_class => "relation" },
    :date_select => { :group => {:append_class => "datetime"} },
    :datetime_select => { :group => {:append_class => "datetime"} },
    :check_box => {
      :group => {:class => "form-item"}, :class => "checkbox",
      :options_position => 0 # check_box does not has the options in last param but first.
    },
    :create_button => {
      :i18n_label_key => "ubiquo.create",
      :class => "bt-update",
    },
    :update_button => {
      :i18n_label_key => "ubiquo.save",
      :class => "bt-update",
    },
    :back_button => {
      :i18n_label_key => "ubiquo.back_to_list",
    }
  })
  context.add( :groups_configuration,{
      :div => {:content_tag => :div, :class => "form-item"},
      :fieldset => {
        :content_tag => :fieldset, 
        :callbacks => {
          :before =>
            lambda do |context, options|
              # Render the legend tag
              legend_options = options[:legend] || options[:label] || {}
              context.eval("@template").content_tag(:legend, legend_options)
            end
        }
      },
      :tabbed => { :content_tag => :div, :append_class => "form-tab-container" },
      # This group config is used for each tab
      :tab => {:content_tag => :fieldset, :append_class => "form-tab",
        :callbacks => {
          :before =>
            lambda do |context, options|
              # Render the legend tag
              legend_options = options.delete(:legend) || options.delete(:label) || {}
              context.eval("@template").content_tag(:legend, legend_options)
            end
        }
      },
      # Configuration for disabled tab wrapper
      :tabbed_unfolded => { :content_tag => :div, :append_class => "form-tab-container-unfolded" },
      :submit_group => {:content_tag => :div, :class => "form-item-submit"},
      :translatable => {:content_tag => :p, :class => "translation-info"},
      :description  => {:content_tag => :p, :class => "description"},
      :help         => {:partial => "/shared/ubiquo/form_parts/form_help"}
    })
  context.add( :default_group_type, :div )
  # Set to false to unfold the group(:type => :tabbed)
  context.add( :unfold_tabs, false)
end
