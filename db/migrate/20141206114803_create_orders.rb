class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.references :product, index: true
      t.string :locale
      t.float :price_original
      t.integer :price_yen
      t.integer :cost
      t.integer :shipping_cost
      t.integer :profit
      t.date :sold_at
      t.text :memo

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
