class CreateWidgets < ActiveRecord::Migration
  def self.up
    uhook_create_widgets_table do |t|
      t.string :name
      t.text :options
      t.integer :block_id
      t.integer :position
      t.string :type

      t.timestamps
    end
    add_index :widgets, :block_id
    add_index :widgets, :type
  end

  def self.down
    drop_table :widgets
  end
end
