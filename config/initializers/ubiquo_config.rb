Ubiquo::Config.add do |config|
  config.app_name = "pjax"
  config.app_title = "Pjax"
  config.app_description = "Pjax"

  Ubiquo::Config.set(:edit_on_row_click, false)

  case RAILS_ENV
  when 'development', 'test'
    config.notifier_email_from = 'railsmail@gnuine.com'
  else
    config.notifier_email_from = 'railsmail@gnuine.com'
  end
end
