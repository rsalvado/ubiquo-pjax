module UbiquoCategories
  module CategorySelector
    module Helper

      # Renders a category selector in a form
      #   key: CategorySet key (required)
      #   options(optional):
      #     type (:checkbox, :select, :autocomplete)
      #     name (Used as the selector title)
      #     set  (CategorySet to obtains selector categories)
      #     include_blank (defaults to false, true to show a blank option if applicable)
      #     autocomplete_style (:tag, :list)
      #   html_options: options for the wrapper (optional)
      def category_selector(object_name, key, options = {}, html_options = {})
        object = options[:object]
        categorize_options = object.class.categorize_options(key)
        raise UbiquoCategories::CategorizationNotFoundError unless categorize_options
        options[:set] ||= category_set(categorize_options[:from] || key.to_s.pluralize)
        categories = uhook_categories_for_set(options[:set], object)
        selector_type = options[:type].try(:to_sym)
        categorize_size = categorize_options[:size]
        max = Ubiquo::Config.context(:ubiquo_categories).get(:max_categories_simple_selector)
        selector_type ||= case categories.size
          when 0..max
            (categorize_size == :many || categorize_size > 1) ? :checkbox : :select
          else
            :autocomplete
        end
        html_options.reverse_merge!({
          :class => "group relation-selector relation-type-#{selector_type}"
        })
        wrapper_type = selector_type == :checkbox ? :fieldset : :div
        output = content_tag(wrapper_type, html_options) do
          wrapper_title = options[:name] || object.class.human_attribute_name(key)
          (wrapper_type == :fieldset ? content_tag(:legend, wrapper_title) : "") +
            send("category_#{selector_type}_selector",
               object, object_name, key, categories, options.delete(:set), options)
        end
        output
      end

      protected

      def category_set(key)
        CategorySet.find_by_key(key.to_s) ||
        CategorySet.find_by_key(key.singularize) ||
        raise(SetNotFoundError.new(key))
      end

      def convert_to_tree(set)
        (map = {}).tap do
          set.each do |element|
            (map[element.parent_id] ||= []) << element
          end
        end
      end

      # Creates a set of checkboxes given for the set of given +categories+
      # +options+ can be
      #   css_class:  ul's css class. Defaults to 'check_list'
      #   extra:      string to add at the end of the li
      def checkbox_area(object, object_name, key, categories, options = {})
        options.reverse_merge!({:css_class => 'category-group'})
        content_tag(:div, :class => options[:css_class]) do
          categories.map do |category|
            is_checked = if options[:checked]
              options[:checked]
            elsif object.send(key).present?
              object.send(key).has_category?(category)
            elsif object.new_record?
              Array(options[:default]).include?(category.name)
            end
            content_tag(:div, :class => "form-item-inline") do
              check_box_tag("#{object_name}[#{key}][]", category.name,
                is_checked,
                { :id => "#{object_name}_#{key}_#{category.id}" }.merge(options)) + ' ' +
                label_tag("#{object_name}_#{key}_#{category.id}", category) +
                options[:extra].to_s
            end
          end.join
        end
      end

      def category_checkbox_selector(object, object_name, key, categories, set, options = {})
        tree = convert_to_tree(categories)
        output = ''
        if tree.keys.size == 1
          output = checkbox_area(object, object_name, key, categories,
            { :default => options[:default] })
        else
          tree.each_pair do |parent, children|
            output << checkbox_area(object, object_name, key,
              categories.select{|c| c.id == parent},
              {
                :default => options[:default],
                :css_class => 'hierarchical_check_list',
                :extra => checkbox_area(object, object_name, key, children,
                  :css_class => 'children_check_list check_list'
                )
              }
            )
          end
        end

        # hidden field without value is required when you want remove
        # all your selection values
        output << hidden_field_tag("#{object_name}[#{key}][]", '')
        output << category_controls("checkbox", object_name, key, set.is_editable?, options).to_s
        output
      end

      def category_select_selector(object, object_name, key, categories, set, options = {})
        blank_name = options[:include_blank] if options[:include_blank].kind_of?(String)
        categories_for_select = options[:include_blank] ? [[blank_name, nil]] : []
        categories_for_select += categories.collect { |cat| [cat.name, cat.name] }
        selected_value = if options[:selected]
          options[:selected]
        elsif object.send(key).present?
          object.send(key).name
        elsif object.new_record?
          options[:default]
        end
        output = content_tag(:div, :class => "form-item") do
          label_caption = options[:name] || object.class.human_attribute_name(key)
          label_tag("#{object_name}[#{key}][]", label_caption) +
            select_tag(
            "#{object_name}[#{key}][]",
            options_for_select(categories_for_select, :selected => selected_value),
            { :id => "#{object_name}_#{key}_select" }.merge(options)
          )
        end
        output << category_controls("select", object_name, key, set.is_editable?, options).to_s
        output
      end

      def category_autocomplete_selector(object, object_name, key, categories, set, options = {})
        style = options[:autocomplete_style] || "tag"
        unless ["list", "tag"].include?(style)
          raise "Invalid option for autocomplete_style"
        end
        url_params = { :category_set_id => set.id, :format => :js }
        current_values = if object.send(key).present?
          Array(object.send(key))
        elsif object.new_record? && options[:default].present?
          options[:default].map { |value| { :name => value } }
        else
          []
        end
        autocomplete_options = {
          :url => ubiquo_category_set_categories_path(url_params),
          :current_values => Array(object.send(key)).to_json(:only => [:id, :name]),
          :style => style
        }
        obj_size = object.class.instance_variable_get(:@categorized_with_options)[key][:size] || :many
        size = (obj_size == :many ? 'null' : obj_size.to_i)

        js_code =<<-JS
          document.observe('dom:loaded', function() {
            var autocomplete = new AutoCompleteSelector(
              '#{autocomplete_options[:url]}',
              '#{object_name}',
              '#{key}',
              #{autocomplete_options[:current_values]},
              '#{autocomplete_options[:style]}',
              #{set.is_editable?},
              #{size}
            )
          });
        JS
        label_caption = options[:name] || object.class.human_attribute_name(key)
        output = javascript_tag(js_code)
        output << content_tag(:div, :class => "form-item") do
          label_tag("#{object_name}[#{key}][]", label_caption) +
          text_field_tag("#{object_name}[#{key}][]", "",
                         :id => "#{object_name}_#{key}_autocomplete")
        end
        output
      end

      def category_controls(type, object_name, key, set_editable, options = {})
        if set_editable && !options[:hide_controls]
          new_category_controls(type, object_name, key)
         end
      end

      def new_category_controls(type, object_name, key)
        content_tag(:div, :class => "new_category_controls") do
          link_to(t("ubiquo.category_selector.new_element"), '#',
                  :id => "link_new__#{type}__#{object_name}__#{key}",
                  :class => "bt-add-category") +
          content_tag(:div, :class => "add_new_category form-item", :style => "display:none") do
            text_field_tag("new_#{object_name}_#{key}", "", :id => "new_#{object_name}_#{key}") +
            link_to(t("ubiquo.category_selector.add_element"), "#", :class => "bt-create-category")
          end
        end
      end
    end
  end
end


# Helper method for form builders
module ActionView
  module Helpers
    class FormBuilder
      def category_selector(key, options = {}, html_options = {})
        options = options.merge(:object => @object)
        @template.category_selector(@object_name, key, options, html_options)
      end
    end
  end
end
