class AddLocaleToUsers < ActiveRecord::Migration
  def self.up
    add_column :ubiquo_users, :locale, :string
  end

  def self.down
    remove_column :ubiquo_users, :locale
  end
end
