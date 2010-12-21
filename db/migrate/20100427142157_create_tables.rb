class CreateTables < ActiveRecord::Migration
  def self.up
    create_table :queries do |t|
      t.string :name
      t.string :aggregate
      t.string :variable
      t.string :rows
      t.string :columns
      t.text :filters
      t.timestamps
    end
  end

  def self.down
    drop_table :queries
  end
end
