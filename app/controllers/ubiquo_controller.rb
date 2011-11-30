class UbiquoController < ApplicationController

  before_filter :login_required
  layout "ubiquo/default"

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '6faa39e2a1b8aa0107b74f23f58bb636'

  def self.default_tiny_mce_options
    { 
      :theme => 'advanced',
      :theme_advanced_toolbar_location => "top",
      :theme_advanced_toolbar_align => "left",
      :theme_advanced_resizing => true,
      :theme_advanced_resize_horizontal => false,
      :paste_auto_cleanup_on_paste => true,
      :theme_advanced_buttons1 => %w{bold italic underline strikethrough separator justifyleft justifycenter justifyright separator 
forecolor backcolor separator code separator undo redo indent outdent separator bullist numlist separator link unlink image},
      :theme_advanced_buttons2 => [],
      :theme_advanced_buttons3 => [],
      :plugins => %w{contextmenu paste media},
      :editor_selector => "visual_editor",
      :entities => "", # disables html entities replace
      :extended_valid_elements => "script[*],style[*]"
    }
  end
  
end
