require "test_helper"

class BookTest < ActiveSupport::TestCase
  setup do
    @author = authors(:one)
    @category = categories(:one)
  end

  test "valid book saves successfully" do
    book = Book.new(
      title: "Test Book",
      isbn: "978-9999999999",
      publication_year: 2024,
      author: @author,
      category: @category,
      available: true
    )
    assert book.valid?
  end

  test "requires title" do
    book = Book.new(isbn: "978-9999999999", publication_year: 2024, author: @author, category: @category)
    assert_not book.valid?
    assert_includes book.errors[:title], "can't be blank"
  end

  test "requires unique isbn" do
    existing = books(:one)
    duplicate = Book.new(
      title: "Another Book",
      isbn: existing.isbn,
      publication_year: 2020,
      author: @author,
      category: @category
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:isbn], "has already been taken"
  end

  test "cover_url returns cover_image_url when present" do
    book = Book.new(cover_image_url: "https://covers.openlibrary.org/b/id/12345-L.jpg")
    assert_equal "https://covers.openlibrary.org/b/id/12345-L.jpg", book.cover_url
  end

  test "cover_url falls back to default open library cover when isbn is present" do
    book = Book.new(isbn: "9780451524935")
    assert_equal "https://covers.openlibrary.org/b/isbn/9780451524935-L.jpg", book.cover_url
  end

  test "cover_url returns blob path when cover_image is attached" do
    book = books(:one)
    book.cover_image.attach(
      io: StringIO.new("fake image data"),
      filename: "test_cover.jpg",
      content_type: "image/jpeg"
    )
    assert book.cover_image.attached?
    assert_includes book.cover_url, "test_cover.jpg"
  end
end
