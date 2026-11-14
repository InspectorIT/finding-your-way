require "test_helper"

class AppointmentsControllerTest < ActionDispatch::IntegrationTest
  test "client can request an available slot" do
    profile = create_profile
    slot = create_slot(profile, starts_at: 1.day.from_now.change(usec: 0))
    client = create_client

    post auth_login_url, params: {
      email: client.email,
      password: "password123"
    }

    assert_redirected_to root_url

    assert_difference("Appointment.count", 1) do
      post appointments_url, params: { slot_id: slot.id }
    end

    appointment = Appointment.order(:id).last

    assert_equal client, appointment.client
    assert_equal slot, appointment.slot
    assert_redirected_to psychologist_url(
                           profile,
                           calendar: profile.id,
                           anchor: "psychologist-#{profile.id}-calendar"
                         )
  end

  test "client cannot book an already occupied slot" do
    profile = create_profile
    slot = create_slot(profile, starts_at: 1.day.from_now.change(usec: 0))
    original_client = create_client

    another_client = User.create!(
      email: "another-client@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Другой клиент",
      phone: "+79994445567",
      role: :client
    )

    existing_appointment = Appointment.create!(
      client: original_client,
      slot: slot
    )

    post auth_login_url, params: {
      email: another_client.email,
      password: "password123"
    }

    assert_redirected_to root_url

    assert_no_difference("Appointment.count") do
      post appointments_url, params: { slot_id: slot.id }
    end

    assert_redirected_to psychologist_url(
                           profile,
                           calendar: profile.id,
                           anchor: "psychologist-#{profile.id}-calendar"
                         )
    assert_equal existing_appointment, slot.reload.appointment
  end

  test "psychologist cannot book own slot" do
    profile = create_profile
    slot = create_slot(profile, starts_at: 1.day.from_now.change(usec: 0))
    psychologist = profile.user

    post auth_login_url, params: {
      email: psychologist.email,
      password: "password123"
    }

    assert_redirected_to root_url

    assert_no_difference("Appointment.count") do
      post appointments_url, params: { slot_id: slot.id }
    end

    assert_redirected_to psychologist_url(profile)
    assert_nil slot.reload.appointment
  end

  test "client can reschedule appointment to another slot with the same psychologist" do
    profile = create_profile
    original_slot = create_slot(
      profile,
      starts_at: 1.day.from_now.change(usec: 0)
    )
    new_slot = create_slot(
      profile,
      starts_at: 2.days.from_now.change(usec: 0)
    )
    client = create_client

    appointment = Appointment.create!(
      client: client,
      slot: original_slot
    )

    sign_in(client)

    assert_no_difference("Appointment.count") do
      patch appointment_url(appointment), params: {
        slot_id: new_slot.id
      }
    end

    assert_equal new_slot, appointment.reload.slot

    assert_redirected_to psychologist_url(
                           profile,
                           calendar: profile.id,
                           anchor: "psychologist-#{profile.id}-calendar"
                         )
  end

  test "client can reschedule appointment to another psychologist" do
    first_profile = create_profile
    second_profile = create_profile(
      email: "another-psychologist@example.com"
    )

    original_slot = create_slot(
      first_profile,
      starts_at: 1.day.from_now.change(usec: 0)
    )
    new_slot = create_slot(
      second_profile,
      starts_at: 2.days.from_now.change(usec: 0)
    )

    client = create_client

    appointment = Appointment.create!(
      client: client,
      slot: original_slot
    )

    sign_in(client)

    assert_no_difference("Appointment.count") do
      patch appointment_url(appointment), params: {
        slot_id: new_slot.id
      }
    end

    assert_equal new_slot, appointment.reload.slot

    assert_redirected_to psychologist_url(
                           second_profile,
                           calendar: second_profile.id,
                           anchor: "psychologist-#{second_profile.id}-calendar"
                         )
  end

  test "client cannot reschedule appointment to an occupied slot" do
    profile = create_profile

    original_slot = create_slot(
      profile,
      starts_at: 1.day.from_now.change(usec: 0)
    )
    occupied_slot = create_slot(
      profile,
      starts_at: 2.days.from_now.change(usec: 0)
    )

    client = create_client
    another_client = create_client(
      email: "another-client@example.com"
    )

    appointment = Appointment.create!(
      client: client,
      slot: original_slot
    )

    Appointment.create!(
      client: another_client,
      slot: occupied_slot
    )

    sign_in(client)

    patch appointment_url(appointment), params: {
      slot_id: occupied_slot.id
    }

    assert_equal original_slot, appointment.reload.slot

    assert_redirected_to psychologist_url(
                           profile,
                           calendar: profile.id,
                           anchor: "psychologist-#{profile.id}-calendar"
                         )
  end

  test "client can cancel own appointment" do
    profile = create_profile
    slot = create_slot(
      profile,
      starts_at: 1.day.from_now.change(usec: 0)
    )
    client = create_client

    appointment = Appointment.create!(
      client: client,
      slot: slot
    )

    sign_in(client)

    assert_difference("Appointment.count", -1) do
      delete appointment_url(appointment)
    end

    assert_redirected_to account_url
  end

  test "client cannot reschedule another client's appointment" do
    profile = create_profile

    original_slot = create_slot(
      profile,
      starts_at: 1.day.from_now.change(usec: 0)
    )
    new_slot = create_slot(
      profile,
      starts_at: 2.days.from_now.change(usec: 0)
    )

    owner = create_client
    another_client = create_client(
      email: "another-client@example.com"
    )

    appointment = Appointment.create!(
      client: owner,
      slot: original_slot
    )

    sign_in(another_client)

    assert_no_difference("Appointment.count") do
      patch appointment_url(appointment), params: {
        slot_id: new_slot.id
      }
    end

    assert_response :not_found
    assert_equal original_slot, appointment.reload.slot
  end

  test "client cannot cancel another client's appointment" do
    profile = create_profile
    slot = create_slot(
      profile,
      starts_at: 1.day.from_now.change(usec: 0)
    )

    owner = create_client
    another_client = create_client(
      email: "another-client@example.com"
    )

    appointment = Appointment.create!(
      client: owner,
      slot: slot
    )

    sign_in(another_client)

    assert_no_difference("Appointment.count") do
      delete appointment_url(appointment)
    end

    assert_response :not_found
    assert Appointment.exists?(appointment.id)
  end

  private

  def create_profile(email: "psychologist@example.com")
    user = User.create!(
      email: email,
      password: "password123",
      password_confirmation: "password123",
      name: "Анна Петрова",
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
      status: :approved
    )
  end

  def create_client(email: "client@example.com")
    User.create!(
      email: email,
      password: "password123",
      password_confirmation: "password123",
      name: "Мария Клиент",
      phone: "+79994445566",
      role: :client
    )
  end

  def sign_in(user)
    post auth_login_url, params: {
      email: user.email,
      password: "password123"
    }

    assert_redirected_to root_url
  end

  def create_slot(profile, starts_at:)
    profile.slots.create!(
      start_time: starts_at,
      end_time: starts_at + profile.session_duration.minutes
    )
  end
end
