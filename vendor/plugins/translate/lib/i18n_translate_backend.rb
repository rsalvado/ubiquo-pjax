module I18n
  module Backend
    module I18nTranslateBackend

        def load_file(filename)
          @current_filename = filename
          super(filename)
        end

        def store_translations(locale, data, options = {})
          if data.is_a?(Hash)
            deep_add_metadata(data, :filename => @current_filename)
            super
          end
        end

        def translate(locale, key, options = {})
          entry = super(locale, key, options)
          entry_with_metadata = lookup(locale, key, options[:scope], options)
          if (metadata = entry_with_metadata.instance_variable_get(:@metadata)).present?
            entry.instance_variable_set(:@metadata, metadata)
          end
          entry
        end

        protected

        def deep_add_metadata value, metadata
          value.each_pair do |key, v|
            v = deep_add_metadata(v, metadata) if v.is_a?(Hash)
            v.instance_variable_set(:@metadata, metadata.clone)
          end
        end
    end
  end
end
