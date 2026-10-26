class AccountController < ApplicationController
  before_action :ensure_logged_in

  def show
    load_appointments
    render :appointments
  end

  def appointments
    load_appointments
  end

  private

  def ensure_logged_in
    return if logged_in?

    redirect_to auth_login_path,
                alert: "Войдите в аккаунт, чтобы открыть личный кабинет."
  end

  def load_appointments
    # Записи, на которые пользователь записался сам.
    @my_appointments =
      if current_user.client? || current_user.psychologist?
        current_user.appointments
                    .joins(:slot)
                    .includes(slot: { psychologist_profile: :user })
                    .order("slots.start_time ASC")
      else
        Appointment.none
      end

    # Записи клиентов к текущему психологу.
    @received_appointments =
      if current_user.psychologist? &&
         current_user.psychologist_profile.present?
        profile = current_user.psychologist_profile

        Appointment.joins(slot: :psychologist_profile)
                   .where(psychologist_profiles: { id: profile.id })
                   .includes(:client, :slot)
                   .order("slots.start_time ASC")
      else
        Appointment.none
      end
  end
end
