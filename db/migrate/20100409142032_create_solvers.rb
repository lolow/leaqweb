class CreateSolvers < ActiveRecord::Migration
  def self.up
    create_table :solvers do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :solvers
  end
end
