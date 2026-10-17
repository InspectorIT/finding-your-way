class SlotsController < ApplicationController
  before_action :require_login
  before_action :require_approved_psychologist

  def index
    @slot = current_user.psychologist_profile.slots.build
    load_slots
  end

  def create
    @slot = current_user.psychologist_profile.slots.build(slot_params)

    if @slot.save
      redirect_to slots_path, notice: "Свободный сеанс добавлен."
    else
      load_slots
      render :index, status: :unprocessable_entity
    end
  end

  private

  def require_approved_psychologist
    profile = current_user&.psychologist_profile

    return if current_user&.psychologist? && profile&.approved?

    head :forbidden
  end

  def slot_params
    params.require(:slot).permit(:start_time, :end_time)
  end

  def load_slots
    @slots = current_user.psychologist_profile
                         .slots
                         .includes(:appointment)
                         .order(:start_time)
  end
end
