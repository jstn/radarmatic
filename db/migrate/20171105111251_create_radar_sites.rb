class CreateRadarSites < ActiveRecord::Migration[5.2]
  def change
    create_table :radar_sites do |t|
      t.string :call_sign
      t.string :name
      t.float :latitude
      t.float :longitude
      t.integer :elevation
      t.boolean :tdwr, default: false, null: false
    end

    add_index :radar_sites, :call_sign, unique: true
  end
end
