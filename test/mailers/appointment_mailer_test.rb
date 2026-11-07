require "test_helper"

class AppointmentMailerTest < ActionMailer::TestCase
  setup do
    @notification = {
      psychologist_email: "psychologist@example.com",
      psychologist_name: "Анна",
      client_name: "Иван",
      specialization: "Когнитивно-поведенческая терапия",
      date: "10.11.2026",
      start_time: "12:00",
      end_time: "12:50"
    }
  end

  test "sends email when a new appointment is created" do
    email = AppointmentMailer
              .with(notification: @notification)
              .booking_created

    assert_equal [ "psychologist@example.com" ], email.to
    assert_equal "Новая запись на консультацию", email.subject

    body = decoded_text(email)

    assert_includes body, "Иван"
    assert_includes body, "12:00"
    assert_includes body, "10.11.2026"
  end

  test "sends email when an appointment is cancelled" do
    email = AppointmentMailer
              .with(notification: @notification)
              .booking_cancelled

    assert_equal [ "psychologist@example.com" ], email.to
    assert_equal "Клиент отменил запись", email.subject

    body = decoded_text(email)

    assert_includes body, "Иван"
    assert_includes body, "отменил запись"
    assert_includes body, "12:00"
  end

  test "sends email when an appointment is rescheduled" do
    notification = @notification.merge(
      previous_date: "10.11.2026",
      previous_start_time: "11:00",
      previous_end_time: "11:50"
    )

    email = AppointmentMailer
              .with(notification: notification)
              .booking_rescheduled

    assert_equal [ "psychologist@example.com" ], email.to
    assert_equal "Клиент перенёс запись", email.subject

    body = decoded_text(email)

    assert_includes body, "Иван"
    assert_includes body, "11:00"
    assert_includes body, "12:00"
  end

  private

  def decoded_text(email)
    email.text_part.body.decoded
  end
end
