class CreateScenarios < ActiveRecord::Migration
  def self.up
    create_table :scenarios do |t|
      t.string :name
      t.belongs_to :energy_system
      t.timestamps
    end
  end

  def self.down
    drop_table :scenarios
  end
end
