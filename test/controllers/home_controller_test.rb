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

  # Проверка, что главная страница успешно загружается и содержит ссылку «Найти психолога», ведущую в каталог
  test "homepage links to psychologist catalog" do
    get root_url

    assert_response :success
    assert_select "a[href=?]", psychologists_path, text: "Найти психолога"
  end
end
