class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.string :name
      t.string :key

      t.timestamps
    end
    add_index :permissions, :key
  end

  def self.down
    drop_table :permissions
  end
end
