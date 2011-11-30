class CreateRolePermissions < ActiveRecord::Migration
  def self.up
    create_table :role_permissions do |t|
      t.integer :role_id
      t.integer :permission_id

      t.timestamps
    end
    
    add_index :role_permissions, [:role_id, :permission_id], :unique=>true
  end

  def self.down
    drop_table :role_permissions
  end
end
