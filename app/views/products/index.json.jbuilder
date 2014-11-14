json.array!(@products) do |product|
  json.extract! product, :id, :asin, :category, :manufacturer, :model, :title, :color, :size, :features, :sales_rank, :url, :url_jp, :image_url1, :image_url2, :image_url3, :image_url4, :image_url5, :currency, :price, :cost, :shipping_cost, :profit, :deleted_at
  json.url product_url(product, format: :json)
end
