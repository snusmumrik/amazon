class Order < ActiveRecord::Base
  belongs_to :product
  acts_as_paranoid

  validates :product_id, :price_original, :price_yen, :cost, :shipping_cost, presence: true

  before_save :calculate_profit
  before_save :shipped?

  def calculate_profit
    exchange_rate = open("public/exchange_rate.txt", "r").read.to_i
    self.profit = self.price_yen * 0.9 - self.cost - self.shipping_cost - (self.price_original * 0.039 + 0.3)*exchange_rate
  end

  def shipped?
    if self.shipped
      self.shipped_at = Date.today
    else
      self.shipped_at = nil
    end
  end
end
