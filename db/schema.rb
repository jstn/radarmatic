# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2017_11_05_111254) do

  create_table "radar_images", force: :cascade do |t|
    t.integer "radar_site_id", null: false
    t.integer "radar_product_id", null: false
    t.binary "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["radar_product_id"], name: "index_radar_images_on_radar_product_id"
    t.index ["radar_site_id", "radar_product_id"], name: "index_radar_images_on_radar_site_id_and_radar_product_id", unique: true
    t.index ["radar_site_id"], name: "index_radar_images_on_radar_site_id"
  end

  create_table "radar_products", force: :cascade do |t|
    t.string "awips_header"
    t.integer "product_code"
    t.string "directory"
    t.string "description"
    t.integer "range"
    t.boolean "tdwr", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["awips_header"], name: "index_radar_products_on_awips_header", unique: true
    t.index ["directory"], name: "index_radar_products_on_directory", unique: true
  end

  create_table "radar_sites", force: :cascade do |t|
    t.string "call_sign"
    t.string "name"
    t.float "latitude"
    t.float "longitude"
    t.integer "elevation"
    t.boolean "tdwr", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["call_sign"], name: "index_radar_sites_on_call_sign", unique: true
  end

end
