class CreateParameterValues < ActiveRecord::Migration
  def self.up
    create_table :parameter_values do |t|
      t.belongs_to :parameter
      t.belongs_to :technology
      t.belongs_to :commodity
      t.belongs_to :aggregate
      t.belongs_to :flow
      t.belongs_to :out_flow
      t.belongs_to :in_flow
      t.belongs_to :market
      t.belongs_to :sub_market
      t.belongs_to :energy_system
      t.belongs_to :scenario, :default => 1, :null => false
      t.integer :year
      t.string  :time_slice
      t.decimal :value, :precision => 20, :scale => 10, :null => false
      t.text    :source
      t.timestamps
    end
    add_index :parameter_values, :parameter_id
    add_index :parameter_values, :technology_id
    add_index :parameter_values, :commodity_id
    add_index :parameter_values, :aggregate_id
    add_index :parameter_values, :flow_id
    add_index :parameter_values, :out_flow_id
    add_index :parameter_values, :in_flow_id
    add_index :parameter_values, :market_id
    add_index :parameter_values, :sub_market_id
    add_index :parameter_values, :energy_system_id
    
  end

  def self.down
    drop_table :parameter_values
  end
end
