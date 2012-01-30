class CreateEnergySystems < ActiveRecord::Migration
  def change
    create_table :energy_systems do |t|
      t.string :name
      t.text :description
      t.timestamps
    end
  end
end
