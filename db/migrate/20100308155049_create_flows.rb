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
    
  end

  def self.down
    drop_table :flows
    drop_table :commodities_flows
  end
end
