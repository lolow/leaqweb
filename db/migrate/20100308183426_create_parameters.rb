class CreateParameters < ActiveRecord::Migration
  def self.up
    create_table :parameters do |t|
      t.string :name
      t.text :definition, :signature, :units
      t.float :default_value
      t.timestamps
    end
    add_index :parameters, :name, :unique => true
  end

  def self.down
    drop_table :parameters
  end
end
