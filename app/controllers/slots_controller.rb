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
      redirect_to slots_path(week: params[:week]), notice: "Свободный сеанс добавлен."
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
    profile = current_user.psychologist_profile

    @week_offset = params.fetch(:week, "0").to_i.clamp(0, 52)

    today = Time.zone.today
    week_start = today.beginning_of_week
    week_start += 1.week if week_start + 4.days < today
    week_start += @week_offset.weeks

    @calendar_days = (0..4).map do |offset|
      week_start + offset.days
    end

    @slots = profile.slots
                    .includes(appointment: :client)
                    .order(:start_time)

    range_start = @calendar_days.first.beginning_of_day
    range_end = (@calendar_days.last + 1.day).beginning_of_day

    visible_slots = @slots.where(start_time: range_start...range_end)
                          .where("slots.start_time > ?", Time.current)

    @slots_by_date = visible_slots.group_by do |slot|
      slot.start_time.to_date
    end
  end
end
