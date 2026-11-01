class SlotsController < ApplicationController
  before_action :require_login
  before_action :require_approved_psychologist
  before_action :set_slot, only: %i[edit update destroy]

  def index
    @slot = current_user.psychologist_profile.slots.build
    load_slots
  end

  def create
    @slot = current_user.psychologist_profile.slots.build(slot_params)

    if @slot.save
      redirect_to slots_path(week: params[:week]),
                  notice: "Свободный сеанс добавлен."
    else
      load_slots
      render :index, status: :unprocessable_entity
    end
  end

  def edit
    @week_offset = params.fetch(:week, "0").to_i.clamp(0, 52)

    if @slot.appointment.present?
      redirect_to slots_path(week: @week_offset),
                  alert: "Нельзя редактировать уже забронированный сеанс."
    end
  end

  def update
    @week_offset = params.fetch(:week, "0").to_i.clamp(0, 52)

    if @slot.appointment.present?
      redirect_to slots_path(week: @week_offset),
                  alert: "Нельзя изменять уже забронированный сеанс."
      return
    end

    if @slot.update(slot_params)
      redirect_to slots_path(week: @week_offset),
                  notice: "Сеанс успешно изменён."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @week_offset = params.fetch(:week, "0").to_i.clamp(0, 52)

    if @slot.appointment.present?
      redirect_to slots_path(week: @week_offset),
                  alert: "Нельзя удалить уже забронированный сеанс."
      return
    end

    if @slot.destroy
      redirect_to slots_path(week: @week_offset),
                  notice: "Свободный сеанс удалён."
    else
      redirect_to slots_path(week: @week_offset),
                  alert: @slot.errors.full_messages.to_sentence
    end
  end

  private

  def require_approved_psychologist
    profile = current_user&.psychologist_profile

    return if current_user&.psychologist? && profile&.approved?

    head :forbidden
  end

  def set_slot
    # Ищем слот только внутри профиля текущего психолога.
    @slot = current_user.psychologist_profile.slots.find(params[:id])
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
