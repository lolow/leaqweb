class CreateSimulations < ActiveRecord::Migration
  def self.up
    create_table :simulations do |t|
      t.string :name, :description
      t.timestamps
    end
  end

  def self.down
    drop_table :simulations
  end
end