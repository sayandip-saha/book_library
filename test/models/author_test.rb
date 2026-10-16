require "test_helper"

class AuthorTest < ActiveSupport::TestCase
  test "requires name" do
    author = Author.new(name: "")
    assert_not author.valid?
    assert_includes author.errors[:name], "can't be blank"
  end

  test "cannot be deleted if books are associated" do
    author = authors(:one)
    assert_not author.destroy
    assert_includes author.errors[:base], "Cannot delete record because dependent books exist"
  end
end
