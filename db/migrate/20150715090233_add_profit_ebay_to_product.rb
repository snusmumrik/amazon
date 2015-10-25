class AddProfitEbayToProduct < ActiveRecord::Migration
  def change
    add_column :products, :profit_ebay, :integer, after: :profit
  end
end
