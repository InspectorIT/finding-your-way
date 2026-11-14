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
      role: :psychologist,
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

  test "approved psychologist can update own free slot" do
    profile = create_profile(
      email: "update-slot-psychologist@example.com",
      role: :psychologist,
      status: :approved
    )

    start_time = 2.days.from_now.change(hour: 10, min: 0, sec: 0)

    slot = profile.slots.create!(
      start_time: start_time,
      end_time: start_time + 50.minutes
    )

    sign_in(profile.user)

    new_start_time = 3.days.from_now.change(hour: 11, min: 0, sec: 0)
    new_end_time = new_start_time + 50.minutes

    assert_no_difference("Slot.count") do
      patch slot_url(slot), params: {
        slot: {
          start_time: new_start_time.iso8601,
          end_time: new_end_time.iso8601
        }
      }
    end

    assert_equal new_start_time.to_i, slot.reload.start_time.to_i
    assert_equal new_end_time.to_i, slot.end_time.to_i
    assert_redirected_to slots_url(week: 0)
  end

  test "approved psychologist can delete own free slot" do
    profile = create_profile(
      email: "delete-slot-psychologist@example.com",
      role: :psychologist,
      status: :approved
    )

    start_time = 2.days.from_now.change(hour: 10, min: 0, sec: 0)

    slot = profile.slots.create!(
      start_time: start_time,
      end_time: start_time + 50.minutes
    )

    sign_in(profile.user)

    assert_difference("Slot.count", -1) do
      delete slot_url(slot)
    end

    assert_redirected_to slots_url(week: 0)
  end

  test "psychologist cannot update an occupied slot" do
    profile = create_profile(
      email: "occupied-update-psychologist@example.com",
      role: :psychologist,
      status: :approved
    )

    start_time = 2.days.from_now.change(hour: 10, min: 0, sec: 0)

    slot = profile.slots.create!(
      start_time: start_time,
      end_time: start_time + 50.minutes
    )

    client = create_user("occupied-update-client@example.com", :client)

    Appointment.create!(
      client: client,
      slot: slot
    )

    sign_in(profile.user)

    new_start_time = 3.days.from_now.change(hour: 11, min: 0, sec: 0)

    assert_no_difference("Slot.count") do
      patch slot_url(slot), params: {
        slot: {
          start_time: new_start_time.iso8601,
          end_time: (new_start_time + 50.minutes).iso8601
        }
      }
    end

    assert_equal start_time.to_i, slot.reload.start_time.to_i
    assert_redirected_to slots_url(week: 0)
  end

  test "psychologist cannot delete an occupied slot" do
    profile = create_profile(
      email: "occupied-delete-psychologist@example.com",
      role: :psychologist,
      status: :approved
    )

    start_time = 2.days.from_now.change(hour: 10, min: 0, sec: 0)

    slot = profile.slots.create!(
      start_time: start_time,
      end_time: start_time + 50.minutes
    )

    client = create_user("occupied-delete-client@example.com", :client)

    Appointment.create!(
      client: client,
      slot: slot
    )

    sign_in(profile.user)

    assert_no_difference("Slot.count") do
      delete slot_url(slot)
    end

    assert Slot.exists?(slot.id)
    assert_redirected_to slots_url(week: 0)
  end

  test "psychologist cannot update another psychologist's slot" do
    owner = create_profile(
      email: "slot-owner@example.com",
      role: :psychologist,
      status: :approved
    )

    another_profile = create_profile(
      email: "another-slot-owner@example.com",
      role: :psychologist,
      status: :approved
    )

    start_time = 2.days.from_now.change(hour: 10, min: 0, sec: 0)

    slot = another_profile.slots.create!(
      start_time: start_time,
      end_time: start_time + 50.minutes
    )

    sign_in(owner.user)

    new_start_time = 3.days.from_now.change(hour: 11, min: 0, sec: 0)

    patch slot_url(slot), params: {
      slot: {
        start_time: new_start_time.iso8601,
        end_time: (new_start_time + 50.minutes).iso8601
      }
    }

    assert_response :not_found
    assert_equal start_time.to_i, slot.reload.start_time.to_i
  end

  test "psychologist cannot delete another psychologist's slot" do
    owner = create_profile(
      email: "another-slot-owner@example.com",
      role: :psychologist,
      status: :approved
    )

    another_profile = create_profile(
      email: "foreign-slot-owner@example.com",
      role: :psychologist,
      status: :approved
    )

    start_time = 2.days.from_now.change(hour: 10, min: 0, sec: 0)

    slot = another_profile.slots.create!(
      start_time: start_time,
      end_time: start_time + 50.minutes
    )

    sign_in(owner.user)

    assert_no_difference("Slot.count") do
      delete slot_url(slot)
    end

    assert_response :not_found
    assert Slot.exists?(slot.id)
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
