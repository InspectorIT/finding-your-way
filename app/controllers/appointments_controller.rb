class AppointmentsController < ApplicationController
  before_action :require_login

  def create
    slot = Slot.find(params[:slot_id])
    profile = slot.psychologist_profile

    if current_user.id == profile.user_id
      redirect_to psychologist_path(profile),
                  alert: "Нельзя записаться на собственный сеанс."
      return
    end

    unless slot.start_time.future? && slot.appointment.nil?
      redirect_to psychologist_path(profile),
                  alert: "Этот слот уже недоступен."
      return
    end

    appointment = current_user.appointments.build(slot: slot)

    if appointment.save
      redirect_to psychologist_path(profile),
                  notice: "Заявка отправлена и ожидает подтверждения."
    else
      redirect_to psychologist_path(profile),
                  alert: appointment.errors.full_messages.to_sentence
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  rescue ActiveRecord::RecordNotUnique
    redirect_to psychologists_path,
                alert: "Этот слот уже забронирован."
  end
end
