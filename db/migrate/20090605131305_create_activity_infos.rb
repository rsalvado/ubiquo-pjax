class CreateActivityInfos < ActiveRecord::Migration
  def self.up
    create_table :activity_infos do |t|
      t.integer :ubiquo_user_id
      t.string :controller
      t.string :action
      t.string :status
      t.text :info
      t.integer :related_object_id
      t.string :related_object_type

      t.timestamps
    end
  end

  def self.down
    drop_table :activity_infos
  end
end
