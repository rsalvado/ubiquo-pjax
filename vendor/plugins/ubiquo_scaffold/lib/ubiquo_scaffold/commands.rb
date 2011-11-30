require 'rails_generator'
require 'rails_generator/commands'
require 'pathname'

begin
  require "ya2yaml"
rescue LoadError
end

module UbiquoScaffold #:nodoc:
  module Generator #:nodoc:
    module Commands #:nodoc:

      module Create

        def update_locale_models(path = '/')
          template_path = Pathname.new(source_path(path))
          translations = UbiquoScaffold::TranslationUpdater.new(template_path)
          translations.update_with('models.yml', 'model-locale.yml', binding) do |models, current_model, locale|
            models[locale]['activerecord']['models'].merge! current_model[locale]['activerecord']['models']
            models[locale]['activerecord']['attributes'].merge! current_model[locale]['activerecord']['attributes']
          end
        end

        def update_ubiquo_locales(path = '/')
          template_path = Pathname.new(source_path(path))
          translations = UbiquoScaffold::TranslationUpdater.new(template_path)
          translations.update_with('ubiquo.yml', 'locale.yml', binding) do |models, current_model, locale|
            models[locale]['ubiquo'].merge! current_model[locale]['ubiquo']
          end
        end

      end

      module Destroy

        def update_locale_models(path = '/')
          template_path = Pathname.new(source_path(path))
          translations = UbiquoScaffold::TranslationUpdater.new(template_path)
          translations.update_with('models.yml', 'model-locale.yml', binding) do |models, current_model, locale|
            models[locale]['activerecord']['models'].delete current_model[locale]['activerecord']['models'].keys.first
            models[locale]['activerecord']['attributes'].delete current_model[locale]['activerecord']['attributes'].keys.first
          end
        end

        def update_ubiquo_locales(path = '/')
          template_path = Pathname.new(source_path(path))
          translations = UbiquoScaffold::TranslationUpdater.new(template_path)
          translations.update_with('ubiquo.yml', 'locale.yml', binding) do |models, current_model, locale|
            models[locale]['ubiquo'].delete current_model[locale]['ubiquo'].keys.first
          end
        end

      end

    end
  end
end

Rails::Generator::Commands::Create.send   :include,  UbiquoScaffold::Generator::Commands::Create
Rails::Generator::Commands::Destroy.send  :include,  UbiquoScaffold::Generator::Commands::Destroy
