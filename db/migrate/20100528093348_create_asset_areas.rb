class CreateAssetAreas < ActiveRecord::Migration
  def self.up
    create_table :asset_areas do |t|
      t.integer :asset_id
      t.string :style
      t.integer :top
      t.integer :left
      t.integer :width
      t.integer :height

      t.timestamps
    end
  end

  def self.down
    drop_table :asset_areas
  end
end
