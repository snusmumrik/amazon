class CreateEbayCategories < ActiveRecord::Migration
  def change
    create_table :ebay_categories do |t|
      t.integer :category_id
      t.integer :category_level
      t.string :category_name
      t.integer :category_parent_id
      t.boolean :leaf_category

      t.timestamps
    end
  end
end
