class Book < ApplicationRecord
  belongs_to :author
  belongs_to :category

  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: true
  validates :publication_year, presence: true
end