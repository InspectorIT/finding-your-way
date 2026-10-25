# Контроллер заявок на профиль психолога
class PsychologistApplicationsController < ApplicationController
  before_action :require_login
  before_action :require_client
  before_action :ensure_application_can_be_submitted

  def new
    @psychologist_profile =
      current_user.psychologist_profile || PsychologistProfile.new
  end

  def create
    @psychologist_profile = current_user.psychologist_profile

    if @psychologist_profile
      # Повторная заявка: используем существующий отклонённый профиль.
      @psychologist_profile.assign_attributes(profile_params)
      @psychologist_profile.status = :pending
    else
      @psychologist_profile =
        current_user.build_psychologist_profile(
          profile_params.merge(status: :pending)
        )
    end

    if @psychologist_profile.save
      redirect_to root_path,
                  notice: "Заявка отправлена на рассмотрение."
    else
      # При неудачной повторной отправке в базе сохраняется статус rejected.
      if @psychologist_profile.persisted?
        @psychologist_profile.status = :rejected
      end

      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_client
    return if current_user&.client?

    redirect_to root_path,
                alert: "Подать заявку может только клиент."
  end

  def ensure_application_can_be_submitted
    profile = current_user&.psychologist_profile
    return if profile.nil? || profile.rejected?

    message =
      if profile.pending?
        "Ваша заявка уже находится на рассмотрении."
      else
        "Ваш профиль психолога уже одобрен."
      end

    redirect_to root_path, alert: message
  end

  def profile_params
    params.require(:psychologist_profile).permit(
      :specialization,
      :experience_years,
      :price_per_session,
      :session_duration,
      :bio,
      :photo
    )
  end
end
