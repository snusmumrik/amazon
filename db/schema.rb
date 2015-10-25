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

ActiveRecord::Schema.define(version: 20150715090233) do

  create_table "categories", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ebay_categories", force: :cascade do |t|
    t.integer  "category_id",        limit: 4
    t.integer  "category_level",     limit: 4
    t.string   "category_name",      limit: 255
    t.integer  "category_parent_id", limit: 4
    t.boolean  "leaf_category",      limit: 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ebay_items", force: :cascade do |t|
    t.integer  "product_id",                        limit: 4
    t.string   "item_id",                           limit: 20
    t.string   "title",                             limit: 255
    t.string   "global_id",                         limit: 255
    t.string   "category_name",                     limit: 255
    t.string   "gallery_url",                       limit: 255
    t.string   "view_item_url",                     limit: 255
    t.string   "shipping_service_cost_currency_id", limit: 3
    t.float    "shipping_service_cost_value",       limit: 24
    t.string   "shipping_type",                     limit: 255
    t.string   "handling_time",                     limit: 2
    t.string   "current_price_currency_id",         limit: 3
    t.float    "current_price_value",               limit: 24
    t.string   "bid_count",                         limit: 255
    t.string   "selling_state",                     limit: 255
    t.boolean  "best_offer_enabled",                limit: 1
    t.boolean  "buy_it_now_available",              limit: 1
    t.datetime "start_time"
    t.datetime "end_time"
    t.string   "listing_type",                      limit: 255
    t.boolean  "returns_accepted",                  limit: 1
    t.string   "condition_display_name",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "ebay_items", ["product_id"], name: "index_ebay_items_on_product_id", using: :btree

  create_table "orders", force: :cascade do |t|
    t.integer  "product_id",     limit: 4
    t.string   "locale",         limit: 255
    t.float    "price_original", limit: 24
    t.integer  "price_yen",      limit: 4
    t.integer  "cost",           limit: 4
    t.integer  "shipping_cost",  limit: 4
    t.integer  "profit",         limit: 4
    t.date     "sold_at"
    t.boolean  "shipped",        limit: 1
    t.date     "shipped_at"
    t.text     "memo",           limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "orders", ["product_id"], name: "index_orders_on_product_id", using: :btree

  create_table "product_to_sells", force: :cascade do |t|
    t.integer  "product_id",  limit: 4
    t.integer  "category_id", limit: 4
    t.boolean  "listed",      limit: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "product_to_sells", ["product_id"], name: "index_product_to_sells_on_product_id", using: :btree

  create_table "products", force: :cascade do |t|
    t.string   "asin",          limit: 255
    t.string   "category",      limit: 255
    t.string   "manufacturer",  limit: 255
    t.string   "model",         limit: 255
    t.text     "title",         limit: 65535
    t.string   "color",         limit: 255
    t.string   "size",          limit: 255
    t.float    "weight",        limit: 24
    t.string   "features",      limit: 255
    t.integer  "sales_rank",    limit: 4
    t.text     "url",           limit: 65535
    t.text     "url_jp",        limit: 65535
    t.string   "image_url1",    limit: 255
    t.string   "image_url2",    limit: 255
    t.string   "image_url3",    limit: 255
    t.string   "image_url4",    limit: 255
    t.string   "image_url5",    limit: 255
    t.string   "currency",      limit: 255
    t.float    "price",         limit: 24
    t.integer  "cost",          limit: 4
    t.integer  "shipping_cost", limit: 4
    t.integer  "profit",        limit: 4
    t.integer  "profit_ebay",   limit: 4
    t.integer  "ebay_average",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "search_indices", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "deleted_at"
  end

  create_table "sort_values", force: :cascade do |t|
    t.integer  "search_index_id", limit: 4
    t.string   "name",            limit: 255
    t.datetime "deleted_at"
  end

  add_index "sort_values", ["search_index_id"], name: "index_sort_values_on_search_index_id", using: :btree

end
