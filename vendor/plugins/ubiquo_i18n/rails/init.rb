require 'ubiquo_i18n'

Ubiquo::Plugin.register(:ubiquo_i18n, directory, config) do |config|
  
  config.add :locales_default_order_field, "native_name"
  config.add :locales_default_sort_order, "ASC"
  config.add :locales_access_control, lambda{
    access_control :DEFAULT => nil
  }

  config.add :last_user_locale, lambda{
    current_ubiquo_user.blank? ? nil : current_ubiquo_user.last_locale rescue nil
  }

  config.add :set_last_user_locale, lambda{ |options|
    begin
      if current_ubiquo_user.present? && current_ubiquo_user.last_locale != options[:locale]
        current_ubiquo_user.last_locale = options[:locale]
        current_ubiquo_user.save
      end
    rescue
      nil
    end
  }
end
