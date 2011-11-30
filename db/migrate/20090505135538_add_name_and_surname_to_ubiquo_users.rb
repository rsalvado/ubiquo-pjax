class AddNameAndSurnameToUbiquoUsers < ActiveRecord::Migration
  def self.up
    add_column :ubiquo_users, :name, :string
    add_column :ubiquo_users, :surname, :string
  end

  def self.down
    remove_column :ubiquo_users, :surname
    remove_column :ubiquo_users, :name
  end
end
