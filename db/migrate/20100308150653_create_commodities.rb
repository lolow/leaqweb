class CreateCommodities < ActiveRecord::Migration
  def self.up
    create_table :commodities do |t|
      t.string :name, :description
      t.boolean :activated, :default => true
      t.belongs_to :demand_driver
      t.decimal :demand_elasticity, :precision => 20, :scale => 10, :default => 1.0
      t.timestamps
    end
    add_index  :commodities, :name, :unique => true
  end

  def self.down
    drop_table :commodities
  end
end
