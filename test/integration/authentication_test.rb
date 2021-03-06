require 'test_helper'

class AuthenticationTest < ActionDispatch::IntegrationTest

  setup do
    ENV['GDS_SSO_MOCK_INVALID'] = '1'
  end

  test "should use GDS SSO to authenticate" do
    get admin_people_path
    assert_redirected_to "/auth/gds"
  end

  test "should allow access when already logged in" do
    login_as_admin
    get admin_people_path
    assert_response :success
  end
end