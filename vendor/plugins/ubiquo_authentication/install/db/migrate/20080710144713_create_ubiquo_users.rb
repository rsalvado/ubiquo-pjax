class CreateUbiquoUsers < ActiveRecord::Migration
  def self.up
    create_table :ubiquo_users do |t|
      t.string :login
      t.string :email
      t.boolean :is_admin
      t.boolean :is_active
      t.string :crypted_password, :limit => 40
      t.string :salt, :limit => 40
      t.string :remember_token
      t.datetime :remember_token_expires_at
      
      t.string :photo_file_name
      t.integer :photo_file_size
      t.string :photo_content_type

      t.timestamps
    end
    add_index :ubiquo_users, :login, :unique=>true
  end

  def self.down
    drop_table :ubiquo_users
  end
end
