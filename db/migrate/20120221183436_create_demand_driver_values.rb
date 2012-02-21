class CreateDemandDriverValues < ActiveRecord::Migration
  def self.up
    create_table :demand_driver_values do |t|
      t.belongs_to :demand_driver
      t.belongs_to :energy_system
      t.integer :year
      t.decimal :value, :precision => 20, :scale => 10, :null => false
      t.text    :source
      t.timestamps
    end

  end

  def self.down
    drop_table :demand_driver_values
  end
end
