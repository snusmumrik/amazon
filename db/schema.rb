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

ActiveRecord::Schema.define(version: 20141113105330) do

  create_table "products", force: true do |t|
    t.string   "asin"
    t.string   "group"
    t.string   "manufacturer"
    t.string   "model"
    t.string   "title"
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
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
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
