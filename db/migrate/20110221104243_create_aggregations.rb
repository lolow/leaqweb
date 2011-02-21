class CreateAggregations < ActiveRecord::Migration
  def self.up
    create_table :aggregations, :id => false do |t|
      t.belongs_to :aggregate, :class => "Commodity"
      t.belongs_to :component, :class => "Commodity"
    end
  end

  def self.down
    drop_table :aggregations
  end
end
