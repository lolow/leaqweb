class CreateSolvers < ActiveRecord::Migration
  def self.up
    create_table :solvers do |t|
      t.string  :workflow_state
      t.integer :pid, :default => 0
      t.integer :first_year, :nb_periods, :period_duration
      t.string  :language, :scenarios
      t.timestamps
    end
  end

  def self.down
    drop_table :solvers
  end
end
