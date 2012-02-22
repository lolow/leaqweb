class CreateSolverJobs < ActiveRecord::Migration
  def self.up
    create_table :solver_jobs do |t|
      t.string  :language, :scenarios
      t.belongs_to :energy_system
      t.timestamps
    end
  end

  def self.down
    drop_table :solver_jobs
  end
end
