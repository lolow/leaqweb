class CreateTechnologySets < ActiveRecord::Migration
  def self.up
    create_table :technology_sets do |t|
      t.string :name, :slug
      t.text :description
      t.belongs_to :energy_system
      t.timestamps
    end
    create_table :technologies_technology_sets, id: false do |t|
      t.belongs_to :technology_set
      t.belongs_to :technology
    end
  end

  def self.down
    drop_table :technology_sets
    drop_table :technology_sets_technologies
  end
end
