class CreatePages < ActiveRecord::Migration
  def self.up
    uhook_create_pages_table do |t|
      t.string :name
      t.string :url_name
      t.string :key
      t.string :page_template
      t.boolean :is_modified
      t.boolean :is_static
      t.integer :published_id
      t.integer :parent_id
      t.string :meta_title
      t.text :meta_keywords
      t.text :meta_description
      
      t.timestamps
    end
    
    add_index :pages, :url_name
    add_index :pages, :page_template
    add_index :pages, :published_id
    add_index :pages, :parent_id
  end

  def self.down
    drop_table :pages
  end
end
