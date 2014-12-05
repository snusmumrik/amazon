class AddCategoryIdAndListedToProductToSell < ActiveRecord::Migration
  def change
    add_column :product_to_sells, :category_id, :integer, :after => :product_id
    add_column :product_to_sells, :listed, :boolean, :after => :category_id
  end
end
