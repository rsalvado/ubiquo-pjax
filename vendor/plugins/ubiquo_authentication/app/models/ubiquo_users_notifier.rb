class UbiquoUsersNotifier < ActionMailer::Base
  
  #Send a mail to the desired user with a new generated password.
  #It's necesary to specify the host because mailer can't know in what host are running rails
  def forgot_password(user, host)
    locale = user.locale.blank? ? Ubiquo.default_locale : user.locale
    subject I18n.t('ubiquo.auth.new_pass_generated', 
      :app_title => Ubiquo::Config.get(:app_title), 
      :locale => locale)
    recipients user.email
    from Ubiquo::Config.get(:notifier_email_from)
    body :user => user, :host => host
  end
  
  #Send a mail to the desired user with the information of their new account.
  #It's necesary to specify the host because mailer can't know in what host are running rails
  def confirm_creation(user, welcome_message, host)
    locale = user.locale.blank? ? Ubiquo.default_locale : user.locale
    subject I18n.t('ubiquo.auth.new_user_created', 
      :app_title => Ubiquo::Config.get(:app_title), 
      :locale => locale)
    recipients user.email
    from Ubiquo::Config.get(:notifier_email_from)
    
    body :user => user, :host => host, :welcome_message => welcome_message, :locale => locale
  end

end
