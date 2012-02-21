class CreateDemandDrivers < ActiveRecord::Migration
  def self.up
    create_table :demand_drivers do |t|
      t.string :name
      t.text   :description
      t.belong :energy_system
      t.timestamps
    end
    add_index :demand_drivers, :name
  end

  def self.down
    drop_table :demand_drivers
  end
end
