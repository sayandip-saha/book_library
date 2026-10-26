class Book < ApplicationRecord
  belongs_to :author
  belongs_to :category

  has_one_attached :cover_image

  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: true
  validates :publication_year, presence: true

  after_save :attach_cover_from_url, if: -> { cover_image_url.present? && !cover_image.attached? }

  def cover_url
    if cover_image.attached?
      Rails.application.routes.url_helpers.rails_blob_url(cover_image, only_path: true)
    else
      cover_image_url.presence || default_open_library_cover
    end
  end

  def default_open_library_cover
    clean_isbn = isbn.to_s.gsub(/[^0-9X]/i, "")
    clean_isbn.present? ? "https://covers.openlibrary.org/b/isbn/#{clean_isbn}-L.jpg" : nil
  end

  private

  def attach_cover_from_url
    return if cover_image_url.blank? || cover_image.attached?

    clean_url = cover_image_url.strip
    return unless clean_url.start_with?("http://", "https://")

    require "open-uri"
    downloaded_io = URI.parse(clean_url).open(
      "User-Agent" => "BookLibraryApp/1.0",
      read_timeout: 8,
      open_timeout: 8
    )
    safe_isbn = isbn.to_s.gsub(/[^0-9X]/i, "").presence || id.to_s
    cover_image.attach(
      io: downloaded_io,
      filename: "cover_#{safe_isbn}.jpg",
      content_type: downloaded_io.content_type || "image/jpeg"
    )
  rescue StandardError => e
    Rails.logger.warn("Could not attach cover image from URL #{cover_image_url}: #{e.message}")
  end
end