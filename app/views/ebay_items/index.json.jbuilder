json.array!(@ebay_items) do |ebay_item|
  json.extract! ebay_item, :id, :product_id, :item_id, :title, :global_id, :category_name, :gallery_url, :view_item_url, :shipping_service_cost_currency_id, :shipping_service_cost_value, :shipping_type, :handling_time, :current_price_currency_id, :current_price_value, :bid_count, :selling_state, :best_offer_enabled, :buy_it_now_available, :start_time, :end_time, :listing_type, :returns_accepted, :condition_display_name
  json.url ebay_item_url(ebay_item, format: :json)
end
