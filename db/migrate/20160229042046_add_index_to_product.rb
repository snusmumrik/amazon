class AddIndexToProduct < ActiveRecord::Migration
  def change
    add_index :products, :asin
    add_index :products, [:category, :title], length: {title: 64}
    add_index :products, :updated_at
    add_index :products, :created_at
    add_index :products, :profit
    add_index :products, [:deleted_at, :price, :cost]
  end
end
