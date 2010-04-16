class CreateOutputs < ActiveRecord::Migration
  def self.up
    create_table :outputs do |t|
      t.string :name, :description
      t.timestamps
    end
  end

  def self.down
    drop_table :outputs
  end
end
