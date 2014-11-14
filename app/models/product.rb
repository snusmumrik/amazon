class Product < ActiveRecord::Base
  validates :asin, :presence => true
end
