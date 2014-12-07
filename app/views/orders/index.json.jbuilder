json.array!(@orders) do |order|
  json.extract! order, :id, :product_id, :locale, :price_original, :price_yen, :cost, :shipping_cost, :profit, :sold_at
  json.url order_url(order, format: :json)
end
