class AddShippedToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :shipped, :boolean, after: :sold_at
    add_column :orders, :shipped_at, :date, after: :shipped
  end
end
