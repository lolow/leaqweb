class CreateSimulations < ActiveRecord::Migration
  def self.up
    create_table :simulations do |t|
      t.string :name, :description
      t.string :dat_file_name, :mod_file_name, :log_file_name,
               :out_file_name, :csv_file_name
      t.timestamps
    end
  end

  def self.down
    drop_table :simulations
  end
end