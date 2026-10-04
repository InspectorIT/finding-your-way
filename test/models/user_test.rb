require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build_user(attributes = {})
    User.new(
      {
        email: "ivan@example.com",
        password: "password123",
        password_confirmation: "password123",
        name: "Иван Иванов",
        phone: "+79990000000",
        role: :client
      }.merge(attributes)
    )
  end

  test "valid user" do
    assert build_user.valid?
  end

  test "email is required" do
    user = build_user(email: nil)

    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test "email must be unique" do
    build_user.save!

    duplicate = build_user(email: "ivan@example.com")

    assert_not duplicate.valid?
    assert duplicate.errors[:email].any?
  end

  test "email must have valid format" do
    user = build_user(email: "invalid-email")

    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test "name is required" do
    user = build_user(name: nil)

    assert_not user.valid?
    assert user.errors[:name].any?
  end

  test "phone is required" do
    user = build_user(phone: nil)

    assert_not user.valid?
    assert user.errors[:phone].any?
  end

  test "role has expected values" do
    assert_equal 0, User.roles["client"]
    assert_equal 1, User.roles["psychologist"]
    assert_equal 2, User.roles["admin"]
  end

  test "password can be authenticated" do
    user = build_user

    assert user.authenticate("password123")
    assert_not user.authenticate("wrong-password")
  end

  test "user has psychologist profile association" do
    user = build_user

    assert_respond_to user, :psychologist_profile
  end

  test "user has appointments association" do
    user = build_user

    assert_respond_to user, :appointments
  end
end
