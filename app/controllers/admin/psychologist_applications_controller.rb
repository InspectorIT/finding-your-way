
class Admin::PsychologistApplicationsController < ApplicationController
  before_action :require_login
  before_action :require_admin

  def index
    @applications = PsychologistProfile.pending
                                       .includes(:user)
                                       .order(:created_at)
  end

  def update
    @application = PsychologistProfile.find(params[:id])

    case params[:status]
    when "approved"
      if approve_application
        redirect_to admin_psychologist_applications_path,
                    notice: "Профиль психолога одобрен."
      else
        redirect_to admin_psychologist_applications_path,
                    alert: "Заявка уже обработана."
      end
    when "rejected"
      if reject_application
        redirect_to admin_psychologist_applications_path,
                    notice: "Заявка отклонена."
      else
        redirect_to admin_psychologist_applications_path,
                    alert: "Заявка уже обработана."
      end
    else
      redirect_to admin_psychologist_applications_path,
                  alert: "Недопустимое действие."
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  rescue ActiveRecord::RecordInvalid
    redirect_to admin_psychologist_applications_path,
                alert: "Не удалось обработать заявку."
  end

  private

  def require_admin
    return if current_user&.admin?

    head :forbidden
  end

  def approve_application
    updated = false

    @application.with_lock do
      if @application.pending?
        @application.update!(status: :approved)
        @application.user.update!(role: :psychologist)
        updated = true
      end
    end

    updated
  end

  def reject_application
    updated = false

    @application.with_lock do
      if @application.pending?
        @application.update!(status: :rejected)
        updated = true
      end
    end

    updated
  end
end
