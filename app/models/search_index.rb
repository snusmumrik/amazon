class SearchIndex < ActiveRecord::Base
  has_many :sort_values

  acts_as_paranoid
end
