class CreateDriverValues < ActiveRecord::Migration
  def self.up
    create_table :driver_values do |t|
      t.belongs_to :driver
      t.integer :year
      t.decimal :value, :precision => 20, :scale => 10, :null => false
      t.text    :source
      t.timestamps
    end
  end

  def self.down
    drop_table :driver_values
  end
end
