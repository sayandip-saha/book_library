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

  test "should lookup isbn even when unauthenticated" do
    get lookup_books_url(isbn: "0451524934")
    assert_response :success
  end

  test "import requires authentication" do
    post import_books_url, params: { isbn: "9780451524935" }
    assert_redirected_to new_session_url
  end

  test "toggle_availability requires authentication" do
    patch toggle_availability_book_url(@book)
    assert_redirected_to new_session_url
  end

  test "toggle_availability toggles book status when authenticated" do
    sign_in_as(@user)
    initial_status = @book.available
    patch toggle_availability_book_url(@book)
    assert_redirected_to book_url(@book)
    assert_equal !initial_status, @book.reload.available
  end
end
