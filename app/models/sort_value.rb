class SortValue < ActiveRecord::Base
  belongs_to :search_index

  acts_as_paranoid
end
