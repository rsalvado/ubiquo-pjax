require 'translate'

I18n::Backend::Simple.send(:include, I18n::Backend::I18nTranslateBackend)

config.after_initialize do
  Translate::Storage.mode = if defined?(Ubiquo::Config) && Ubiquo::Config.option_exists?(:translate_mode)
    Ubiquo::Config.get(:translate_mode)
  else
    :application
  end

  def I18n.supported_locales
    if defined?(Ubiquo::Config) && Ubiquo::Config.option_exists?(:supported_locales)
      Ubiquo::Config.get(:supported_locales)
    else
      I18n.available_locales
    end
  end 
end
