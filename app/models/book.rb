class Book < ApplicationRecord
  belongs_to :author
  belongs_to :category

  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: true
  validates :publication_year, presence: true

  def cover_url
    cover_image_url.presence || default_open_library_cover
  end

  def default_open_library_cover
    clean_isbn = isbn.to_s.gsub(/[^0-9X]/i, "")
    clean_isbn.present? ? "https://covers.openlibrary.org/b/isbn/#{clean_isbn}-L.jpg" : nil
  end
end