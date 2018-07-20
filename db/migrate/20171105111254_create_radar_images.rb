class CreateRadarImages < ActiveRecord::Migration[5.1]
  def change
    create_table :radar_images do |t|
      t.belongs_to :radar_site, foreign_key: true, null: false, index: true
      t.belongs_to :radar_product, foreign_key: true, null: false, index: true
      t.binary :data
      t.timestamps
    end

    add_index :radar_images, [:radar_site_id, :radar_product_id], unique: true
  end
end
