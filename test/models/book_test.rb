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
end
