module Ubiquo
  module RelationSelector
    class RelationNotFound < StandardError; end
    class NeedNameField < StandardError; end
    module Helper

      # Renders a relation selector in a form
      #   key: relation key (required)
      #   options(optional):
      #     type (:checkbox, :select, :autocomplete)
      #     name_field (Used as the selector name)
      #     autocomplete_style (:tag, :list)
      #     collection_url(:url_string)
      #     url_params(:hash_with_additional_url_params)
      #     required(:true_false_param)
      #     add_callback(:callback_string)
      #     remove_callback(:callback_string)
      #     related_object_id_field(:id_field)
      # options will have an additional parameter giving the
      # related_object field human-readable identifier(s)

      def relation_selector(object_name, key, options = {}, html_options = {})
        object = options[:object]
        if object.respond_to?(key)
          # This part checks reflections
          relation_type, object_class_name = discover_relation_by_reflections(
            object,
            key,
            options
          )
          # This part is setting needed vars for url-craft and populates

          # This part populate needed vars for all selectors
          humanized_field,
          selector_type, relation_type = define_needed_controls(
            object_class_name,
            relation_type,
            key,
            object_name,
            options
          )
          # array of possible values

          # array of possible values
          related_objects = url_craft_settings object_class_name, selector_type, options
          # Finally, output is generated
          html_options.reverse_merge!({
            :class => "group relation-selector relation-type-#{selector_type}"
          })
          wrapper_type = selector_type == :checkbox ? :fieldset : :div
          output = content_tag(wrapper_type, html_options) do
            inst_name = options[:name] || object.class.human_attribute_name(key)
            caption = options[:required] == true ? "#{inst_name} *" : inst_name
            (wrapper_type == :fieldset ? content_tag(:legend, caption) : "") +
              send("relation_#{selector_type}_selector",
              object, object_name, key, related_objects, humanized_field, relation_type, options)
          end
          add_description(output, options.delete(:description))
        else
          raise RelationSelector::RelationNotFound.new
        end
      end

      protected

      def define_needed_controls class_name, relation_type, key, object_name, options = {}
        if options[:name_field].blank?
          sample_obj = class_name.constantize.new
          if sample_obj.respond_to?(:name)
            humanized_field = :name
          elsif sample_obj.respond_to?(:title)
            humanized_field = :title
          else
            raise RelationSelector::NeedNameField.new(
              "You need to specify a :name_field for #{class_name} because " +
              "it was not deduced by convention (i.e. #{class_name} " +
              "does not respond to 'name', 'title'..)"
            )
          end
        else
          humanized_field = options[:name_field]
        end

        if options[:type].blank?
          selector_type = :autocomplete
        else
          selector_type = options[:type]
        end

        if relation_type == :has_many
          options[:key_field] = "#{key.to_s.singularize}_ids"
          options[:initial_text_field_tag_name] = "#{object_name}[#{options[:key_field]}][]"
        else
          options[:key_field] = if options[:real_foreign_key].present?
            options[:real_foreign_key]
          else
            "#{key.to_s.singularize}_id"
          end
          options[:limited_elements] = 1
          options[:initial_text_field_tag_name] = "#{object_name}[#{options[:key_field]}]"
        end
        return humanized_field, selector_type, relation_type
      end

      def url_craft_settings class_name, selector_type, options = {}
        related_objects = []
        if options[:collection_url].blank?
          options[:related_url] = send("new_ubiquo_#{class_name.tableize.singularize}_url")
          options[:collection_url] = "ubiquo_#{class_name.tableize.pluralize}_url"
          if selector_type != :autocomplete
            related_objects = if class_name.constantize.respond_to?(:locale)
              # TODO this should be in a connector
              class_name.constantize.locale(current_locale, :all).all
            else
              class_name.constantize.all
            end
          end
        else
          options[:hide_controls] = true
        end
        options[:related_object_id_field] ||= 'id'
        return related_objects
      end

      def discover_relation_by_reflections object, key, options = {}
        relation_type = nil
        class_name = nil
        object.class.reflections.each do |ref|
          if ref[1].name == key.to_sym
            relation_type = ref[1].macro
            class_name = ref[1].class_name
            if ref[1].options[:foreign_key].present?
              options[:real_foreign_key] = ref[1].options[:foreign_key]
            end
            break
          end
        end
        return [relation_type, class_name]
      end

      def relation_checkbox_selector(object, object_name, key, related_objects, humanized_field, relation_type, options = {})
        current_related_objects = object.send(key).to_a
        if current_related_objects.length > 0
          current_related_objects = current_related_objects.map(&:id).to_a
        end
        options.reverse_merge!({:css_class => 'category-group'})
        output = content_tag(:div, :class => options[:css_class]) do
          related_objects.map do |ro|
            content_tag(:div, :class => 'form-item-inline') do
              check_box_tag("#{object_name}[#{options[:key_field]}][]", ro.id,
                current_related_objects.include?(ro.id),
                :id => "#{object_name}_#{options[:key_field]}_#{ro.id}") +
                label_tag(
                  "#{object_name}_#{options[:key_field]}_#{ro.id}",
                  ro.send(humanized_field)
                )
            end
          end.join
        end
        output << hidden_field_tag("#{object_name}[#{options[:key_field]}][]", '')
        output << relation_controls(options)
        output
      end

      def relation_select_selector(object, object_name, key, related_objects, humanized_field, relation_type, options = {})
        objects_for_select = related_objects.collect { |cat|
          [cat.send(humanized_field), cat.id]
        }
        inst_name = options[:name] || object.class.human_attribute_name(key)
        label_caption = options[:required] == true ? "#{inst_name} *" : inst_name
        output = content_tag(:div, :class => "form-item") do
          label_tag("#{object_name}[#{options[:key_field]}]_select", label_caption) +
            select_tag("#{object_name}[#{options[:key_field]}]",
              options_for_select(objects_for_select,
                :selected => (object.send(key).id rescue '')),
                { :id => "#{object_name}_#{options[:key_field]}_select" })
        end
        output << relation_controls(options)
        output
      end

      def relation_autocomplete_selector(object, object_name, key, related_objects, humanized_field, relation_type, options = {})
        url_params = {:format => :js}
        url_params.merge!(options[:url_params]) if options[:url_params].present?

        autocomplete_options = {
          :url => send(options[:collection_url], url_params),
          :current_values => open_struct_from_model(
            object.send(key),
            options[:related_object_id_field] || 'id',
            humanized_field
          ),
          :style => options[:autocomplete_style] || "tag"
        }
        options[:add_callback] = if options[:add_callback].blank?
          'undefined'
        else
          "'#{options[:add_callback]}'"
        end
        options[:remove_callback] = if options[:remove_callback].blank?
          'undefined'
        else
          "'#{options[:remove_callback]}'"
        end
        js_autocomplete =<<-JS
          var autocomplete = new RelationAutoCompleteSelector(
            '#{autocomplete_options[:url]}',
            '#{object_name}',
            '#{options[:key_field]}',
            #{autocomplete_options[:current_values]},
            '#{autocomplete_options[:style]}',
            #{options[:limited_elements] || 'undefined'},
            '#{humanized_field}',
            '#{options[:related_object_id_field]}',
            #{options[:add_callback]},
            #{options[:remove_callback]}
          )
        JS
        js_code = if (request.format rescue nil) == :js
          js_autocomplete
        else
          "document.observe('dom:loaded', function() { %s })" % js_autocomplete
        end
        inst_name = options[:name] || object.class.human_attribute_name(key)
        label_caption = options[:required] == true ? "#{inst_name} *" : inst_name
        output = javascript_tag(js_code)
        output << content_tag(:div, :class => "form-item") do
          label_tag("#{object_name}[#{key}][]", label_caption) +
            text_field_tag(options[:initial_text_field_tag_name], "",
                           :id => "#{object_name}_#{options[:key_field]}_autocomplete")
        end
        output << relation_controls(options)
      end

      def open_struct_from_model(objects, id_field, key_field)
        [objects].flatten.compact.map do |obj|
          OpenStruct.new(
            id_field.to_sym => obj.send(id_field),
            key_field.to_sym => obj.send(key_field)
          )
        end.to_json
      end

      def relation_controls(options = {})
        if options[:hide_controls] == true
          ''
        elsif options[:related_control].blank?
          content_tag(:div, :class => 'relation_new') do
            link_to I18n.t('ubiquo.new_relation'),
                    options[:related_url],
                    { :class => 'bt-add-category', :rel => 'external' }
          end
        else
          options[:related_control]
        end
      end

      def add_description( content, description )
        return content if description.nil? || !description.kind_of?( String )

        content + content_tag( :p, description, :class => 'description' )
      end
    end
  end
end

# Helper method for form builders
module ActionView
  module Helpers
    class FormBuilder
      def relation_selector(key, options = {}, html_options = {})
        options = options.merge(:object => @object)
        @template.relation_selector(@object_name, key, options, html_options)
      end
    end
  end
end
