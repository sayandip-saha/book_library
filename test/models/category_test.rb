require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "requires name" do
    category = Category.new(name: "")
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "cannot be deleted if books are associated" do
    category = categories(:one)
    assert_not category.destroy
    assert_includes category.errors[:base], "Cannot delete record because dependent books exist"
  end
end
