class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|
      t.string :name
      t.text :description
      t.timestamps
    end
    add_index  :locations, :name, :unique => true
    
    create_table :locations_technologies, :id => false do |t|
      t.belongs_to :location
      t.belongs_to :technology
    end
  end

  def self.down
    drop_table :locations
  end
end
