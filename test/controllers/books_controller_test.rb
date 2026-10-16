require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @book = books(:one)
    @user = users(:one)
  end

  test "should get index even when unauthenticated" do
    get books_url
    assert_response :success
  end

  test "should get show even when unauthenticated" do
    get book_url(@book)
    assert_response :success
  end

  test "should redirect new when unauthenticated" do
    get new_book_url
    assert_redirected_to new_session_url
  end

  test "should get new when authenticated" do
    sign_in_as(@user)
    get new_book_url
    assert_response :success
  end

  test "should get edit when authenticated" do
    sign_in_as(@user)
    get edit_book_url(@book)
    assert_response :success
  end
end
