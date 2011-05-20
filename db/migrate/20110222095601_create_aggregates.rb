class CreateAggregates < ActiveRecord::Migration
  def self.up
    create_table :aggregates do |t|
      t.string :name
      t.text :description
      t.timestamps
    end
    create_table :aggregates_commodities, :id => false do |t|
      t.belongs_to :aggregate
      t.belongs_to :commodity
    end
  end

  def self.down
    drop_table :aggregates
    drop_table :aggregates_commodities
  end
end
