class CreateCommodities < ActiveRecord::Migration
  def self.up
    create_table :commodities do |t|
      t.string :name, :description
      t.boolean :activated, :default => true
      t.timestamps
    end
    add_index  :commodities, :name, :unique => true
  end

  def self.down
    drop_table :commodities
  end
end
