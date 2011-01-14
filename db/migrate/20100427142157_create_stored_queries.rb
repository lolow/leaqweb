class CreateStoredQueries < ActiveRecord::Migration
  def self.up
    create_table :stored_queries do |t|
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
    drop_table :stored_queries
  end
end
