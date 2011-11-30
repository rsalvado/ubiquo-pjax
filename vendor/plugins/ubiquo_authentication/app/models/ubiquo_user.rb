require 'digest/sha1'
class UbiquoUser < ActiveRecord::Base

  has_many :ubiquo_user_roles
  has_many :roles, :through => :ubiquo_user_roles

  # Creates the photo attachment to the user and a resized thumbnail
  file_attachment(:photo, :visibility => "protected",
    :styles => { 
      :thumb => "66x66>" 
    })

  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login
  validates_presence_of     :name
  validates_presence_of     :surname
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_presence_of     :email
  validates_uniqueness_of   :email, :case_sensitive => false
  validates_format_of       :email, :with => /\A([a-z0-9#_.-]+)@([a-z0-9-]+)\.([a-z.]+)\Z/i
  validates_length_of       :login, :within => 3..40
  validates_uniqueness_of   :login, :case_sensitive => false

  before_save :encrypt_password

  # prevents a ubiquo_user from submitting a crafted form that bypasses activation
  # anything else you want your ubiquo_user to change should be added here.
  attr_accessible :login, :email, :password, :password_confirmation, :is_admin, :is_active, :role_ids, :photo, :name, :surname, :locale

  named_scope :admin, lambda {|value|{
              :conditions => {:is_admin => value}
  }}

  named_scope :active, lambda {|value|{
              :conditions => {:is_active => value}
  }}

  filtered_search_scopes :text => [:name, :surname, :login],
                         :enable => [:admin, :active]

  # Magic finder. It's like find_by_id_or_login
  def self.gfind(something, options={})
    case something
    when Fixnum
      find_by_id(something, options)
    when String, Symbol
      find_by_login(something.to_s, options)
    when UbiquoUser
      something
    else
      nil
    end
  end

  # Creates first user. Used when installing ubiquo. It shouldn't work in production mode.
  def self.create_first(login,password)
    unless Rails.env.production? || self.count > 0
      admin_user = {
        :login => login,
        :password => password,
        :password_confirmation => password,
        :email => 'foo@bar.com',
        :name => 'Super',
        :surname => 'Admin',
        :is_active => true,
        :is_admin => true,
        :is_superadmin => true,
        :locale => I18n.locale.to_s
      }
      user = UbiquoUser.create(admin_user)
      unless user.new_record?
        user.update_attribute :is_superadmin, true
      end
      user
    end
  end
  
  # Authenticates a ubiquo_user by their login name and unencrypted password.  Returns the ubiquo_user or nil.
  def self.authenticate(login, password)
    u = find_by_login(login) # need to get the salt
    (u && (u.authenticated?(password) ? u : nil) && (u.is_active? ? u : nil))
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the ubiquo_user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  # These create and unset the fields required for remembering ubiquo_users between browser closes
  def remember_me
    remember_me_for Ubiquo::Config.context(:ubiquo_authentication).get(:remember_time)
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  # The current ubiquo_user will not expire until 'time' is reached
  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("--#{remember_token_expires_at}--")
    save(false)
  end

  # Expire current_ubiquo_user inmediately
  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end
  
  def reset_password!
    (password = ActiveSupport::SecureRandom.base64(6)).tap do
      self.password = password
      self.password_confirmation = password
      self.save
    end
  end

  # Permission methods

  # adds a role to this ubiquo_user
  def add_role(role)
    role=Role.gfind(role)
    return false if role.nil?
    UbiquoUserRole.create_for_ubiquo_user_and_role(self, role)
    self.reload
    true
  end

  # removes a role from this ubiquo_user
  def remove_role(role)
    role=Role.gfind(role)
    return false if role.nil? || !roles.include?(role)
    UbiquoUserRole.destroy_for_ubiquo_user_and_role(self, role)
    self.reload
    true
  end

  # true if this ubiquo_user has specified permission
  def has_permission?(permission)
    return true if self.is_admin?
    permission = Permission.gfind(permission)
    self.roles.each do |role|
      return true if role.has_permission?(permission)
    end
    false
  end
  
  #gives the full name of the user, with name and surname.
  def full_name
    "#{self.surname}, #{self.name}"
  end


  protected
  # before filter
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def password_required?
    crypted_password.blank? || !password.blank?
  end

end
