# Контроллер заявок
class PsychologistApplicationsController < ApplicationController
  before_action :require_login
  before_action :require_client
  before_action :ensure_no_existing_profile

  def new
    @psychologist_profile = PsychologistProfile.new
  end

  def create
    @psychologist_profile =
      current_user.build_psychologist_profile(
        profile_params.merge(status: :pending)
      )

    if @psychologist_profile.save
      redirect_to root_path,
                  notice: "Заявка отправлена на рассмотрение."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_client
    return if current_user&.client?

    redirect_to root_path,
                alert: "Подать заявку может только клиент."
  end

  def ensure_no_existing_profile
    return unless current_user&.psychologist_profile.present?

    redirect_to root_path,
                alert: "Заявка или профиль уже существуют."
  end

  def profile_params
    params.require(:psychologist_profile).permit(
      :specialization,
      :experience_years,
      :price_per_session,
      :session_duration,
      :bio
    )
  end
end
