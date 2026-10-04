require "test_helper"

class AppointmentTest < ActiveSupport::TestCase
  def build_psychologist
    user = User.create!(
      email: "appointment-psychologist@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Психолог",
      phone: "+79995556677",
      role: :psychologist
    )

    PsychologistProfile.create!(
      user: user,
      specialization: "Психология",
      experience_years: 7,
      price_per_session: 3000,
      session_duration: 50,
      bio: "Описание."
    )
  end

  def build_slot
    psychologist = build_psychologist

    Slot.create!(
      psychologist_profile: psychologist,
      start_time: 1.day.from_now.change(hour: 12, min: 0),
      end_time: 1.day.from_now.change(hour: 12, min: 50)
    )
  end

  def build_client
    User.create!(
      email: "appointment-client@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Клиент",
      phone: "+79996667788",
      role: :client
    )
  end

  def build_appointment(attributes = {})
    Appointment.new(
      {
        client: build_client,
        slot: build_slot,
        status: :pending
      }.merge(attributes)
    )
  end

  test "valid appointment" do
    assert build_appointment.valid?
  end

  test "appointment belongs to client" do
    appointment = build_appointment

    assert_instance_of User, appointment.client
  end

  test "appointment belongs to slot" do
    appointment = build_appointment

    assert_instance_of Slot, appointment.slot
  end

  test "pending status is valid" do
    appointment = build_appointment(status: :pending)

    assert appointment.valid?
  end

  test "confirmed status is valid" do
    appointment = build_appointment(status: :confirmed)

    assert appointment.valid?
  end

  test "slot can have only one appointment" do
    slot = build_slot
    client_one = build_client
    client_two = User.create!(
      email: "another-client@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Другой клиент",
      phone: "+79997778899",
      role: :client
    )

    Appointment.create!(
      client: client_one,
      slot: slot,
      status: :pending
    )

    second_appointment = Appointment.new(
      client: client_two,
      slot: slot,
      status: :pending
    )

    assert_not second_appointment.valid?
  end
end
