class CreateAssetGeometries < ActiveRecord::Migration
  def self.up
    create_table :asset_geometries do |t|
      t.integer :asset_id
      t.string  :style
      t.float   :width
      t.float   :height

      t.timestamps
    end
  end

  def self.down
    drop_table :asset_geometries
  end
end
