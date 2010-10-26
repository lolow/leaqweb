class CreateParameterValues < ActiveRecord::Migration
  def self.up
    create_table :parameter_values do |t|
      t.belongs_to :parameter
      t.belongs_to :technology
      t.belongs_to :commodity
      t.belongs_to :flow
      t.belongs_to :out_flow
      t.belongs_to :in_flow
      t.belongs_to :market
      t.integer :year
      t.string  :time_slice
      t.decimal :value, :precision => 20, :scale => 10, :null => false
      t.text    :source
      t.timestamps
    end
  end

  def self.down
    drop_table :parameter_values
  end
end
