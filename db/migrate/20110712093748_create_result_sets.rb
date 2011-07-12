class CreateResultSets < ActiveRecord::Migration
  def self.up
    create_table :result_sets do |t|
      t.string :name, :description
      t.timestamps
    end
  end

  def self.down
    drop_table :result_sets
  end
end
