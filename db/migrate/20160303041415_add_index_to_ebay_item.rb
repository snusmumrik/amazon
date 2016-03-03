class AddIndexToEbayItem < ActiveRecord::Migration
  def change
    add_index :ebay_items, [:product_id, :selling_state]
  end
end
