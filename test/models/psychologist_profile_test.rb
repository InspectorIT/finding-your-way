require "test_helper"

class PsychologistProfileTest < ActiveSupport::TestCase
  def build_user
    User.create!(
      email: "psychologist@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Анна Петрова",
      phone: "+79991112233",
      role: :psychologist
    )
  end

  def build_profile(attributes = {})
    PsychologistProfile.new(
      {
        user: build_user,
        specialization: "Клиническая психология",
        experience_years: 5,
        price_per_session: 3000,
        session_duration: 50,
        bio: "Помогаю справляться с тревожностью."
      }.merge(attributes)
    )
  end

  test "valid psychologist profile" do
    assert build_profile.valid?
  end

  test "belongs to user" do
    profile = build_profile
    user = profile.user

    assert_instance_of User, user
  end

  test "specialization is required" do
    profile = build_profile(specialization: nil)

    assert_not profile.valid?
  end

  test "bio is required" do
    profile = build_profile(bio: nil)

    assert_not profile.valid?
  end

  test "experience years cannot be negative" do
    profile = build_profile(experience_years: -1)

    assert_not profile.valid?
  end

  test "experience years can be zero" do
    profile = build_profile(experience_years: 0)

    assert profile.valid?
  end

  test "price per session must be greater than zero" do
    profile = build_profile(price_per_session: 0)

    assert_not profile.valid?
  end

  test "session duration must be greater than zero" do
    profile = build_profile(session_duration: 0)

    assert_not profile.valid?
  end
end
