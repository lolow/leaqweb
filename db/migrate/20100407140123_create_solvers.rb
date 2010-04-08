class CreateSolvers < ActiveRecord::Migration
  def self.up
    create_table :solvers do |t|
      t.string :workflow_state
      t.integer :pid
      t.belongs_to :user
      t.timestamps
    end
  end

  def self.down
    drop_table :solvers
  end
end
