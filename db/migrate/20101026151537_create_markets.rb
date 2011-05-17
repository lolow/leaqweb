class CreateMarkets < ActiveRecord::Migration
  def self.up
    create_table :markets do |t|
      t.string :name
      t.text   :description
      t.timestamps
    end
    create_table :markets_technologies, :id => false do |t|
      t.belongs_to :market
      t.belongs_to :technology
    end
    add_index :markets_technologies, :market_id
    add_index :markets_technologies, :technology_id
  end

  def self.down
    drop_table :markets
    drop_table :markets_technologies
  end
end
