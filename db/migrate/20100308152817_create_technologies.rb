class CreateTechnologies < ActiveRecord::Migration
  def self.up
    create_table :technologies do |t|
      t.string :name, :slug
      t.text   :description
      t.belongs_to :energy_system
      t.timestamps
    end
    add_index  :technologies, :name, unique: true
  end

  def self.down
    drop_table :technologies
  end
end
