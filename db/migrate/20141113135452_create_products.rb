class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :asin
      t.string :category
      t.string :manufacturer
      t.string :model
      t.text :title
      t.string :color
      t.string :size
      t.string :features
      t.integer :sales_rank
      t.text :url
      t.text :url_jp
      t.string :image_url1
      t.string :image_url2
      t.string :image_url3
      t.string :image_url4
      t.string :image_url5
      t.string :currency
      t.float :price
      t.integer :cost
      t.integer :shipping_cost
      t.integer :profit

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
