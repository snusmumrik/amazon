class ProductToSell < ActiveRecord::Base
  belongs_to :product
  validates :product_id, uniqueness: true
  acts_as_paranoid
end
