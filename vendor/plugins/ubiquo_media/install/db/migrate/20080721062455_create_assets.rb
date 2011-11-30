class CreateAssets < ActiveRecord::Migration
  def self.up
    uhook_create_assets_table do |t|
      t.string :name
      t.text :description
      t.integer :asset_type_id
      t.string :resource_file_name
      t.integer :resource_file_size
      t.string :resource_content_type
      t.string :type
      t.boolean :is_protected
      
      t.timestamps
    end
  end

  def self.down
    drop_table :assets
  end
end
