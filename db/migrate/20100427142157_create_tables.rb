class CreateTables < ActiveRecord::Migration
  def self.up
    create_table :tables do |t|
      t.string :name
      t.string :aggregate
      t.string :variable
      t.string :rows
      t.string :columns
      t.string :filters
      t.timestamps
    end
  end

  def self.down
    drop_table :tables
  end
end
