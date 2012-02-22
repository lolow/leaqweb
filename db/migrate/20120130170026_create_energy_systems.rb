class CreateEnergySystems < ActiveRecord::Migration
  def change
    create_table :energy_systems do |t|
      t.string :name
      t.text :description
      t.integer :first_year, :nb_periods, :period_duration
      t.timestamps
    end
  end
end
