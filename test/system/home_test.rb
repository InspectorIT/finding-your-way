require "application_system_test_case"

class HomeTest < ApplicationSystemTestCase
  test "home page loads" do
    visit root_path

    assert_selector "h1", text: "Добро пожаловать в Finding Your Way"
  end
end
