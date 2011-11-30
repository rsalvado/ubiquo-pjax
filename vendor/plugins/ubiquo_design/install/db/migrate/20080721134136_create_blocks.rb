class CreateBlocks < ActiveRecord::Migration
  def self.up
    create_table :blocks do |t|
      t.string :block_type
      t.integer :page_id
      t.integer :shared_id
      t.boolean :is_shared, :default => false
      
      t.timestamps
    end
    add_index :blocks, :block_type
    add_index :blocks, :page_id
  end

  def self.down
    drop_table :blocks
  end
end
