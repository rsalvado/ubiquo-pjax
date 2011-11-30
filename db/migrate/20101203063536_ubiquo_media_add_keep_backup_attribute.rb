class UbiquoMediaAddKeepBackupAttribute < ActiveRecord::Migration
  def self.up
    add_column :assets, :keep_backup, :boolean, :default => true
  end

  def self.down
    remove_column :assets, :keep_backup
  end
end
