class Order < ActiveRecord::Base
  belongs_to :product
  acts_as_paranoid

  validates :product_id, :price_original, :price_yen, :cost, :shipping_cost, presence: true

  before_save :calculate_profit

  def calculate_profit
    exchange_rate = open("public/exchange_rate.txt", "r").read.to_i
    self.profit = self.price_yen - self.cost - self.shipping_cost
  end
end
