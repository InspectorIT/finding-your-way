require "test_helper"

class SlotsControllerTest < ActionDispatch::IntegrationTest
  test "approved psychologist can create a slot for own profile" do
    profile = create_profile(
      email: "approved-psychologist@example.com",
      role: :psychologist,
      status: :approved
    )
    sign_in(profile.user)

    start_time = 2.days.from_now.change(hour: 10, min: 0, sec: 0)
    end_time = start_time + 50.minutes

    assert_difference("Slot.count", 1) do
      post slots_url, params: {
        slot: {
          start_time: start_time.iso8601,
          end_time: end_time.iso8601
        }
      }
    end

    created_slot = Slot.order(:id).last

    assert_equal profile.id, created_slot.psychologist_id
    assert_equal start_time.to_i, created_slot.start_time.to_i
    assert_redirected_to slots_url
  end

  test "client cannot create a slot" do
    client = create_user("client@example.com", :client)
    sign_in(client)

    assert_no_difference("Slot.count") do
      post slots_url, params: {
        slot: {
          start_time: 2.days.from_now.iso8601,
          end_time: 2.days.from_now.advance(minutes: 50).iso8601
        }
      }
    end

    assert_response :forbidden
  end

  test "pending applicant cannot manage slots" do
    profile = create_profile(
      email: "pending-applicant@example.com",
      role: :client,
      status: :pending
    )
    sign_in(profile.user)

    get slots_url

    assert_response :forbidden
  end

  test "slot in the past cannot be created" do
    profile = create_profile(
      email: "past-slot-psychologist@example.com",
      role: :psychologist,
      status: :approved
    )
    sign_in(profile.user)

    start_time = 1.hour.ago
    end_time = start_time + 50.minutes

    assert_no_difference("Slot.count") do
      post slots_url, params: {
        slot: {
          start_time: start_time.iso8601,
          end_time: end_time.iso8601
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "overlapping slots cannot be created" do
    profile = create_profile(
      email: "overlap-psychologist@example.com",
      role: :psychologist,
      status: :approved
    )
    sign_in(profile.user)

    start_time = 2.days.from_now.change(hour: 10, min: 0, sec: 0)

    profile.slots.create!(
      start_time: start_time,
      end_time: start_time + 50.minutes
    )

    assert_no_difference("Slot.count") do
      post slots_url, params: {
        slot: {
          start_time: (start_time + 30.minutes).iso8601,
          end_time: (start_time + 80.minutes).iso8601
        }
      }
    end

    assert_response :unprocessable_entity
  end

  private

  def sign_in(user)
    post auth_login_url, params: {
      email: user.email,
      password: "password123"
    }

    assert_redirected_to root_url
  end

  def create_user(email, role)
    User.create!(
      email: email,
      password: "password123",
      password_confirmation: "password123",
      name: email.split("@").first,
      phone: "+79990000001",
      role: role
    )
  end

  def create_profile(email:, role:, status:)
    user = create_user(email, role)

    PsychologistProfile.create!(
      user: user,
      specialization: "Клиническая психология",
      experience_years: 5,
      price_per_session: 3000,
      session_duration: 50,
      bio: "Работа с тревожностью",
      status: status
    )
  end
end
