class Product < ActiveRecord::Base
  has_many :ebay_items
  validates :asin, presence: true
  validates :asin, uniqueness: true
  acts_as_paranoid
end
