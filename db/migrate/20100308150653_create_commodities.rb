class CreateCommodities < ActiveRecord::Migration
  def self.up
    create_table :commodities do |t|
      t.string :name, :definition
      t.timestamps
    end
    add_index  :commodities, :name, :unique => true
  end

  def self.down
    remove_column :name, :definition
    drop_table :commodities
  end
end
