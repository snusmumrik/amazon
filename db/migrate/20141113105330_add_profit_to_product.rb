class AddProfitToProduct < ActiveRecord::Migration
  def change
    add_column :products, :shipping_cost, :integer, after: :cost
    add_column :products, :profit, :integer, after: :shipping_cost
  end
end
