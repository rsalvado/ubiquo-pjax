class CreateUbiquoUserRoles < ActiveRecord::Migration
  def self.up
    create_table :ubiquo_user_roles do |t|
      t.integer :ubiquo_user_id
      t.integer :role_id

      t.timestamps
    end
    add_index :ubiquo_user_roles, [:ubiquo_user_id, :role_id], :unique=>true
  end

  def self.down
    drop_table :ubiquo_user_roles
  end
end
