class AddVersionIdToWidget < ActiveRecord::Migration
  def self.up
 	add_column :widgets, :version, :integer, :default => 0 
  end

  def self.down
	remove_column :widgets, :version
  end
end
