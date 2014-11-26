# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20141125061620) do

  create_table "ebay_items", force: true do |t|
    t.integer  "product_id"
    t.string   "item_id",                           limit: 20
    t.string   "title"
    t.string   "global_id"
    t.string   "category_name"
    t.string   "gallery_url"
    t.string   "view_item_url"
    t.string   "shipping_service_cost_currency_id", limit: 3
    t.float    "shipping_service_cost_value"
    t.string   "shipping_type"
    t.string   "handling_time",                     limit: 2
    t.string   "current_price_currency_id",         limit: 3
    t.float    "current_price_value"
    t.string   "bid_count"
    t.string   "selling_state"
    t.boolean  "best_offer_enabled"
    t.boolean  "buy_it_now_available"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string   "listing_type"
    t.boolean  "returns_accepted"
    t.string   "condition_display_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "ebay_items", ["product_id"], name: "index_ebay_items_on_product_id", using: :btree

  create_table "product_to_sells", force: true do |t|
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "product_to_sells", ["product_id"], name: "index_product_to_sells_on_product_id", using: :btree

  create_table "products", force: true do |t|
    t.string   "asin"
    t.string   "category"
    t.string   "manufacturer"
    t.string   "model"
    t.text     "title"
    t.string   "color"
    t.string   "size"
    t.string   "features"
    t.integer  "sales_rank"
    t.text     "url"
    t.text     "url_jp"
    t.string   "image_url1"
    t.string   "image_url2"
    t.string   "image_url3"
    t.string   "image_url4"
    t.string   "image_url5"
    t.string   "currency"
    t.float    "price"
    t.integer  "cost"
    t.integer  "shipping_cost"
    t.integer  "profit"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "search_indices", force: true do |t|
    t.string   "name"
    t.datetime "deleted_at"
  end

  create_table "sort_values", force: true do |t|
    t.integer  "search_index_id"
    t.string   "name"
    t.datetime "deleted_at"
  end

  add_index "sort_values", ["search_index_id"], name: "index_sort_values_on_search_index_id", using: :btree

end
