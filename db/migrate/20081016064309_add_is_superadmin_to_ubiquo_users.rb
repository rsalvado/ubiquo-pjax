class AddIsSuperadminToUbiquoUsers < ActiveRecord::Migration
  def self.up
    add_column :ubiquo_users, :is_superadmin, :boolean
  end

  def self.down
    remove_column :ubiquo_users, :is_superadmin
  end
end
