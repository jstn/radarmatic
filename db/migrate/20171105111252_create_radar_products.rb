class CreateRadarProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :radar_products do |t|
      t.string :awips_header
      t.integer :product_code
      t.string :directory
      t.string :description
      t.integer :range
      t.boolean :tdwr, default: false, null: false
      t.timestamps
    end

    add_index :radar_products, :awips_header, unique: true
    add_index :radar_products, :directory, unique: true
  end
end
