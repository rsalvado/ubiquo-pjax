class Role < ActiveRecord::Base
  has_many :role_permissions, :dependent => :destroy
  has_many :permissions, :through => :role_permissions

  has_many :ubiquo_user_roles, :dependent => :destroy
  has_many :ubiquo_users, :through => :ubiquo_user_roles

  validates_presence_of :name

  # magic finder. It's like an find_by_id_or_name
  def self.gfind(something, options={})
    case something
    when Fixnum
      find_by_id(something, options)
    when String, Symbol
      find_by_name(something.to_s, options)
    when Role
      something
    else
      nil
    end
  end
    
  def self.find_available_for_ubiquo_user(ubiquo_user)
    ubiquo_user=UbiquoUser.gfind(ubiquo_user)
    return find(:all) if ubiquo_user.nil?
    role_ids = ubiquo_user.roles.map(&:id)
    return find(:all) if role_ids.blank?
    find(:all, :conditions => ["id not in (?)", role_ids])
  end
  
  # adds a permission to current role. Returns true if OK or false if not
  def add_permission(permission)
    permission=Permission.gfind(permission)
    return false if permission.nil? || permissions.include?(permission)
    permissions.push(permission)
    true
  end

  # removes a permission from the current role. returns true if OK or false if not
  def remove_permission(permission)
    permission=Permission.gfind(permission)
    return false if permission.nil? || !permissions.include?(permission)
    permissions.delete(permission)
    true
  end
  
  
  # returns true if this role has the passed permission
  def has_permission?(permission)
    permission=Permission.gfind(permission)
    permissions.reload.include?(permission)
  end
  
end
