class CreateLocales < ActiveRecord::Migration
  def self.up
    create_table :locales do |t|
      t.string :iso_code
      t.string :english_name
      t.string :native_name
      t.boolean :is_active, :default => false
      t.boolean :is_default, :default => false
    end
  end

  def self.down
    drop_table :locales
  end
end
