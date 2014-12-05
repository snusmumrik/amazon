class EbayCategory < ActiveRecord::Base
  validates :category_id, uniqueness: true
end
