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

  private

  def create_profile
    user = User.create!(
      email: "psychologist@example.com",
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

  def create_client
    User.create!(
      email: "client@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Мария Клиент",
      phone: "+79994445566",
      role: :client
    )
  end

  def create_slot(profile, starts_at:)
    profile.slots.create!(
      start_time: starts_at,
      end_time: starts_at + profile.session_duration.minutes
    )
  end
end
