require "test_helper"

class PsychologistsControllerTest < ActionDispatch::IntegrationTest
  test "index shows approved psychologist profiles only" do
    create_profile(
      name: "Анна Петрова",
      email: "anna@example.com",
      status: :approved
    )

    create_profile(
      name: "Павел Сидоров",
      email: "pavel@example.com",
      status: :pending
    )

    get psychologists_url

    assert_response :success
    assert_includes response.body, "Анна Петрова"
    refute_includes response.body, "Павел Сидоров"
  end

  test "sorts psychologists by nearest available slot" do
    later_profile = create_profile(
      name: "Анна Петрова",
      email: "anna@example.com",
      status: :approved
    )

    sooner_profile = create_profile(
      name: "Павел Сидоров",
      email: "pavel@example.com",
      status: :approved
    )

    create_slot(later_profile, starts_at: 3.days.from_now)
    create_slot(sooner_profile, starts_at: 1.day.from_now)

    get psychologists_url(sort: "soonest")

    assert_response :success

    assert_operator(
      response.body.index("Павел Сидоров"),
      :<,
      response.body.index("Анна Петрова")
    )
  end

  test "index provides a link to sort by soonest available slot" do
    get psychologists_url

    assert_response :success
    assert_select "a[href=?]",
                  psychologists_path(sort: "soonest"),
                  text: "Ближайший свободный сеанс"
  end

  test "show displays approved psychologist and available slots" do
    profile = create_profile(
      name: "Анна Петрова",
      email: "anna-show@example.com",
      status: :approved
    )
    starts_at = 1.day.from_now.change(sec: 0)
    slot = create_slot(profile, starts_at: starts_at)

    get psychologist_url(profile)

    assert_response :success
    assert_select "h1", "Анна Петрова"
    assert_includes response.body, "Клиническая психология"
    assert_includes response.body,
                    slot.start_time.strftime("%d.%m.%Y %H:%M")
  end

  test "show does not expose a pending profile" do
    profile = create_profile(
      name: "Павел Сидоров",
      email: "pavel-show@example.com",
      status: :pending
    )

    get psychologist_url(profile)

    assert_response :not_found
    refute_includes response.body, "Павел Сидоров"
  end

  private

  def create_profile(name:, email:, status:)
    user = User.create!(
      email: email,
      password: "password123",
      password_confirmation: "password123",
      name: name,
      phone: "+79991112233",
      role: :psychologist
    )

    PsychologistProfile.create!(
      user: user,
      specialization: "Клиническая психология",
      experience_years: 5,
      price_per_session: 3000,
      session_duration: 50,
      bio: "Помогаю справляться с тревожностью.",
      status: status
    )
  end

  def create_slot(profile, starts_at:)
    profile.slots.create!(
      start_time: starts_at,
      end_time: starts_at + profile.session_duration.minutes
    )
  end
end
