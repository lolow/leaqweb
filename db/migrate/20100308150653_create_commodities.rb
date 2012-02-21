class CreateCommodities < ActiveRecord::Migration
  def self.up
    create_table :commodities do |t|
      t.string     :name, :description, :slug
      t.belongs_to :demand_driver
      t.belongs_to :energy_systems
      t.decimal    :default_demand_elasticity, :precision => 20, :scale => 10, :default => 1.0
      t.timestamps
    end
    add_index  :commodities, :name, :unique => true
    add_index  :commodities, :demand_driver_id
    add_index  :users, :slug, unique: true
  end

  def self.down
    drop_table :commodities
  end
end
