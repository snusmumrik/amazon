class CreateEbayItems < ActiveRecord::Migration
  def change
    create_table :ebay_items do |t|
      t.references :product, index: true
      t.string :item_id, limit: 20
      t.string :title
      t.string :global_id
      t.string :category_name
      t.string :gallery_url
      t.string :view_item_url
      t.string :shipping_service_cost_currency_id, limit: 3
      t.float :shipping_service_cost_value
      t.string :shipping_type
      t.string :handling_time, limit: 2
      t.string :current_price_currency_id, limit: 3
      t.float :current_price_value
      t.string :bid_count
      t.string :selling_state
      t.boolean :best_offer_enabled
      t.boolean :buy_it_now_available
      t.datetime :start_time
      t.datetime :end_time
      t.string :listing_type
      t.boolean :returns_accepted
      t.string :condition_display_name

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
