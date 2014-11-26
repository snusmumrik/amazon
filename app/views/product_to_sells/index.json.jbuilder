json.array!(@product_to_sells) do |product_to_sell|
  json.extract! product_to_sell, :id, :product_id
  json.url product_to_sell_url(product_to_sell, format: :json)
end
