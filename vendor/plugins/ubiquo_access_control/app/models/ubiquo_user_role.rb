class UbiquoUserRole < ActiveRecord::Base
  
  belongs_to :ubiquo_user
  belongs_to :role

  # creates a relation between ubiquo_user and role
  def self.create_for_ubiquo_user_and_role(ubiquo_user, role)
    role=Role.gfind(role)
    ubiquo_user=UbiquoUser.gfind(ubiquo_user)
    
    !role.nil? && !ubiquo_user.nil? && (find_by_ubiquo_user_id_and_role_id(ubiquo_user, role) || create(:ubiquo_user => ubiquo_user, :role => role))
  end

  # destroy a relation between ubiquo_user and role
  def self.destroy_for_ubiquo_user_and_role(ubiquo_user, role)
    role=Role.gfind(role)
    ubiquo_user=UbiquoUser.gfind(ubiquo_user)

    rel = find_by_ubiquo_user_id_and_role_id(ubiquo_user, role)
    return nil if rel.nil?
    rel.destroy
  end
end
