class CreateCombustions < ActiveRecord::Migration
  def self.up
    create_table :combustions do |t|
      t.belongs_to :fuel,      :class => "Commodity"
      t.belongs_to :pollutant, :class => "Commodity"
      t.decimal    :value, :precision => 20, :scale => 10, :null => false
      t.text       :source
      t.timestamps
    end
    add_index :combustions, :fuel_id
    add_index :combustions, :pollutant_id
  end

  def self.down
    drop_table :combustions
  end
end
