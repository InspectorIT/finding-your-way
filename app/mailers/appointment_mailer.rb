class AppointmentMailer < ApplicationMailer
  def booking_created
    @notification = params.fetch(:notification)

    mail(
      to: @notification.fetch(:psychologist_email),
      subject: "Новая запись на консультацию"
    )
  end

  def booking_cancelled
    @notification = params.fetch(:notification)

    mail(
      to: @notification.fetch(:psychologist_email),
      subject: "Клиент отменил запись"
    )
  end

  def booking_rescheduled
    @notification = params.fetch(:notification)

    mail(
      to: @notification.fetch(:psychologist_email),
      subject: "Клиент перенёс запись"
    )
  end
end
