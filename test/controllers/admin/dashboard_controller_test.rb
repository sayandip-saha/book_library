require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @regular_user = users(:two)
  end

  test "redirects unauthenticated users to login" do
    get admin_root_url
    assert_redirected_to new_session_url
  end

  test "redirects regular non-admin users to root" do
    sign_in_as(@regular_user)
    get admin_root_url
    assert_redirected_to root_url
    assert_equal "Access restricted. Administrator privileges required.", flash[:alert]
  end

  test "allows admin to view dashboard" do
    sign_in_as(@admin)
    get admin_root_url
    assert_response :success
    assert_select "h1", "Library Operations Dashboard"
  end

  test "allows admin to view users list" do
    sign_in_as(@admin)
    get admin_users_url
    assert_response :success
    assert_select "h1", "Manage User Accounts"
  end

  test "allows admin to toggle another user admin status" do
    sign_in_as(@admin)
    assert_not @regular_user.admin?

    patch toggle_admin_admin_user_url(@regular_user)
    assert_redirected_to admin_users_url
    assert @regular_user.reload.admin?

    patch toggle_admin_admin_user_url(@regular_user)
    assert_redirected_to admin_users_url
    assert_not @regular_user.reload.admin?
  end

  test "prevents admin from revoking own admin status" do
    sign_in_as(@admin)
    patch toggle_admin_admin_user_url(@admin)
    assert_redirected_to admin_users_url
    assert_equal "You cannot revoke your own administrator privileges.", flash[:alert]
    assert @admin.reload.admin?
  end

  test "allows admin to create a new admin account" do
    sign_in_as(@admin)
    assert_difference("User.count", 1) do
      post admin_users_url, params: {
        user: {
          email_address: "new_director@booklibrary.com",
          password: "password123",
          password_confirmation: "password123",
          admin: "1"
        }
      }
    end
    assert_redirected_to admin_users_url
    new_user = User.find_by(email_address: "new_director@booklibrary.com")
    assert new_user.present?
    assert new_user.admin?
  end

  test "allows admin to delete another user account" do
    sign_in_as(@admin)
    assert_difference("User.count", -1) do
      delete admin_user_url(@regular_user)
    end
    assert_redirected_to admin_users_url
  end
end

