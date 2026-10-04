require "test_helper"

class SlotTest < ActiveSupport::TestCase
  def build_user
    User.create!(
      email: "slot-psychologist@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Иван Петров",
      phone: "+79992223344",
      role: :psychologist
    )
  end

  def build_profile
    PsychologistProfile.create!(
      user: build_user,
      specialization: "Психология",
      experience_years: 10,
      price_per_session: 3500,
      session_duration: 50,
      bio: "Описание психолога."
    )
  end

  def build_slot(attributes = {})
    Slot.new(
      {
        psychologist_profile: build_profile,
        start_time: 1.day.from_now.change(hour: 10, min: 0),
        end_time: 1.day.from_now.change(hour: 10, min: 50)
      }.merge(attributes)
    )
  end

  test "valid slot" do
    assert build_slot.valid?
  end

  test "start time is required" do
    slot = build_slot(start_time: nil)

    assert_not slot.valid?
  end

  test "end time is required" do
    slot = build_slot(end_time: nil)

    assert_not slot.valid?
  end

  test "end time must be after start time" do
    slot = build_slot(
      start_time: 1.day.from_now.change(hour: 15, min: 0),
      end_time: 1.day.from_now.change(hour: 14, min: 0)
    )

    assert_not slot.valid?
    assert_includes slot.errors[:end_time],
                    "должно быть позже времени начала"
  end

  test "equal start and end times are invalid" do
    time = 1.day.from_now.change(hour: 15, min: 0)

    slot = build_slot(
      start_time: time,
      end_time: time
    )

    assert_not slot.valid?
  end

  test "slot belongs to psychologist profile" do
    slot = build_slot

    assert_instance_of PsychologistProfile, slot.psychologist_profile
  end

  test "slot without appointment is free" do
    slot = build_slot

    assert_nil slot.appointment
  end

  test "slot with appointment is occupied" do
    slot = build_slot
    slot.save!

    client = User.create!(
      email: "client@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Петр Иванов",
      phone: "+79994445566",
      role: :client
    )

    appointment = Appointment.create!(
      client: client,
      slot: slot,
      status: :pending
    )

    assert_equal appointment, slot.appointment
  end
end
