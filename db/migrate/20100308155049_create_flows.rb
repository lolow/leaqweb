class CreateFlows < ActiveRecord::Migration
  def self.up
    create_table :flows do |t|
      t.belongs_to :technology
      t.string :type
      t.timestamps
    end

    create_table :commodities_flows, :id => false do |t|
      t.belongs_to :flow
      t.belongs_to :commodity
    end

    add_index :flows, :technology_id
    add_index :flows, :type

    add_index :commodities_flows, :flow_id
    add_index :commodities_flows, :commodity_id

  end

  def self.down
    drop_table :flows
    drop_table :commodities_flows
  end
end
