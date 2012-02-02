class CreateCombustions < ActiveRecord::Migration
  def self.up
    create_table :combustions do |t|
      t.string     :fuel, :null => false
      t.string     :pollutant, :null => false
      t.decimal    :value, :precision => 20, :scale => 10, :null => false
      t.text       :source
      t.timestamps
    end
    add_index :combustions, :fuel
    add_index :combustions, :pollutant
  end

  def self.down
    drop_table :combustions
  end
end
