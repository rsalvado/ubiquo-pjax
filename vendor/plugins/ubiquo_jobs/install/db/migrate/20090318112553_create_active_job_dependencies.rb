class CreateActiveJobDependencies < ActiveRecord::Migration
  def self.up
    create_table :active_job_dependencies do |t|
      t.column :previous_job_id, :integer, :null => false
      t.column :next_job_id, :integer, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :active_job_dependencies
  end
end
