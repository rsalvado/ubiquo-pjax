class AddLastLocaleToUbiquoUser < ActiveRecord::Migration
  def self.up
    add_column :ubiquo_users, :last_locale, :string
  end

  def self.down
    remove_column :ubiquo_users, :last_locale
  end
end
