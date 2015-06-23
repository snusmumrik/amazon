class AddEbayProfitToProduct < ActiveRecord::Migration
  def up
    add_column :products, :ebay_average, :integer, after: :profit
  end

  def down
    remove_column :products, :ebay_average
  end
end
