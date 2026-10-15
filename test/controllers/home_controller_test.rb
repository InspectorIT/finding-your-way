require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
  end

  test "should get ui_kit" do
    get ui_kit_url
    assert_response :success
  end
end
