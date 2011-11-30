class CreateCategoryRelations < ActiveRecord::Migration
  def self.up
    uhook_create_category_relations_table do |t|
      t.integer :category_id
      t.integer :related_object_id
      t.string :related_object_type
      t.integer :position
      t.string :attr_name
      t.timestamps

      t.index :category_id
      t.index :related_object_type
      t.index [:related_object_id, :related_object_type]
    end
  end

  def self.down
    drop_table :category_relations
  end
end
