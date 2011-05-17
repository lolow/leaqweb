class CreateTechnologies < ActiveRecord::Migration
  def self.up
    create_table :technologies do |t|
      t.string :name
      t.text   :description
      t.timestamps
    end
    add_index  :technologies, :name, :unique => true
  end

  def self.down
    drop_table :technologies
  end
end
