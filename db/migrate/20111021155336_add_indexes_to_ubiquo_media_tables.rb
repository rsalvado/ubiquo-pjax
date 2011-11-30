class AddIndexesToUbiquoMediaTables < ActiveRecord::Migration
  def self.up
    add_index :assets, :asset_type_id
    add_index :asset_relations, [:related_object_type, :related_object_id]
    add_index :asset_relations, :asset_id
    add_index :asset_areas, :asset_id
    add_index :asset_geometries, :asset_id
  end

  def self.down
    remove_index :assets, :asset_type_id
    remove_index :asset_relations, [:related_object_type, :related_object_id]
    remove_index :asset_relations, :asset_id
    remove_index :asset_areas, :asset_id
    remove_index :asset_geometries, :asset_id
  end
end
