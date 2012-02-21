class CreateCommoditySets < ActiveRecord::Migration
  def self.up
    create_table :commodity_sets do |t|
      t.string :name, :slug
      t.text :description
      t.belongs_to :energy_system
      t.timestamps
    end
    create_table :commodities_commodity_sets, :id => false do |t|
      t.belongs_to :commodity_set
      t.belongs_to :commodity
    end
  end

  def self.down
    drop_table :commodity_sets
    drop_table :commodity_sets_commodities
  end
end
