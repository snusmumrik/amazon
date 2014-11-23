class EbayItem < ActiveRecord::Base
  belongs_to :product
  validates :item_id, uniqueness: true
  acts_as_paranoid
end
