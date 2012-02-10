class CreateCommoditySets < ActiveRecord::Migration
  def self.up
    create_table :commodity_sets do |t|
      t.string :name
      t.text :description
      t.timestamps
    end
    create_table :commodity_sets_commodities, :id => false do |t|
      t.belongs_to :commodity_set
      t.belongs_to :commodity
    end
  end

  def self.down
    drop_table :commodity_sets
    drop_table :commodity_sets_commodities
  end
end
