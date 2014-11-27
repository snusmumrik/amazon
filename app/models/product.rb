class Product < ActiveRecord::Base
  has_many :ebay_items
  validates :asin, presence: true
  validates :asin, uniqueness: true
  acts_as_paranoid

  before_update :calculate_cost

  def calculate_cost
    @exchange_rate = open("public/exchange_rate.txt", "r").read.to_i
    @shipping_cost = 1080
    @exchange_rate = open("public/exchange_rate.txt", "r").read.to_i
    self.profit = self.price * @exchange_rate - @shipping_cost - self.cost
  end
end
