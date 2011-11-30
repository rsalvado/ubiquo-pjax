class CreateActiveJobs < ActiveRecord::Migration
  def self.up
    create_table :active_jobs do |t|
      t.string :runner
      t.string :command
      t.integer :tries, :default => 0
      t.integer :priority, :null => false
      t.integer :lock_version, :default => 0
      t.datetime :planified_at
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :result_code
      t.text :result_output
      t.text :result_error
      t.text :stored_options
      t.string :notify_to
      t.integer :state
      t.string :name
      t.string :type

      t.timestamps
    end
  end

  def self.down
    drop_table :active_jobs
  end
end
