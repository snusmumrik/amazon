class AddWeightToProduct < ActiveRecord::Migration
  def change
    add_column :products, :weight, :float, after: :size
  end
end
