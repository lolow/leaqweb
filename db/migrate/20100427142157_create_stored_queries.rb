class CreateStoredQueries < ActiveRecord::Migration
  def self.up
    create_table :stored_queries do |t|
      t.string :name, :aggregate, :variable, :rows, :columns
      t.text :filters
      t.timestamps
    end
  end

  def self.down
    drop_table :stored_queries
  end
end
