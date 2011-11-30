# == Schema Information
# Schema version: 7
#
# Table name: role_permissions
#
#  id            :integer       not null, primary key
#  role_id       :integer       
#  permission_id :integer       
#  created_at    :datetime      
#  updated_at    :datetime      
#

class RolePermission < ActiveRecord::Base
  belongs_to :role
  belongs_to :permission
end
