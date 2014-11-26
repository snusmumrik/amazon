class CreateProductToSells < ActiveRecord::Migration
  def change
    create_table :product_to_sells do |t|
      t.references :product, index: true

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
