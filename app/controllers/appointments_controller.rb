class AppointmentsController < ApplicationController
  before_action :require_login
  before_action :set_appointment, only: %i[update destroy]

  def create
    unless booking_allowed?
      redirect_to root_path,
                  alert: "Записываться могут только клиенты и психологи."
      return
    end

    slot = Slot.find(params[:slot_id])
    profile = slot.psychologist_profile

    if current_user.id == profile.user_id
      redirect_to psychologist_path(profile),
                  alert: "Нельзя записаться на собственный сеанс."
      return
    end

    if current_user.appointments.exists?
      redirect_to account_path,
                  alert: "У вас уже есть запись. Перенесите или отмените её."
      return
    end

    unless available_slot?(slot)
      redirect_to calendar_path(profile),
                  alert: "Этот слот уже недоступен."
      return
    end

    appointment = current_user.appointments.build(slot: slot)

    if appointment.save
      redirect_to calendar_path(profile),
                  notice: "Вы записаны на сеанс."
    else
      redirect_to account_path,
                  alert: appointment.errors.full_messages.to_sentence
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  rescue ActiveRecord::RecordNotUnique
    redirect_to account_path,
                alert: "У вас уже есть запись или этот слот уже занят."
  end

  def update
    unless booking_allowed?
      redirect_to root_path,
                  alert: "Переносить запись могут только клиенты и психологи."
      return
    end

    slot = Slot.find(params[:slot_id])
    profile = slot.psychologist_profile

    if current_user.id == profile.user_id
      redirect_to psychologist_path(profile),
                  alert: "Нельзя записаться на собственный сеанс."
      return
    end

    if slot.id == @appointment.slot_id
      redirect_to calendar_path(profile),
                  notice: "Вы уже записаны на это время."
      return
    end

    unless available_slot?(slot)
      redirect_to calendar_path(profile),
                  alert: "Это время уже занято или недоступно."
      return
    end

    if @appointment.update(slot: slot)
      redirect_to calendar_path(profile),
                  notice: "Вы успешно перенесены на новое время."
    else
      redirect_to account_path,
                  alert: @appointment.errors.full_messages.to_sentence
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  rescue ActiveRecord::RecordNotUnique
    redirect_to psychologists_path,
                alert: "Это время уже забронировано другим клиентом."
  end

  def destroy
    @appointment.destroy

    redirect_to account_path,
                notice: "Ваша запись отменена. Теперь вы можете выбрать другое время."
  end

  private

  def set_appointment
    # Пользователь может изменять и удалять только собственную запись.
    @appointment = current_user.appointments.find(params[:id])
  end

  def booking_allowed?
    current_user.client? || current_user.psychologist?
  end

  def available_slot?(slot)
    slot.start_time.future? &&
      slot.appointment.nil? &&
      slot.psychologist_profile.approved?
  end

  def calendar_path(profile)
    if params[:return_to_home] == "1"
      root_path(
        calendar: profile.id,
        week: params[:week],
        anchor: "psychologist-#{profile.id}-calendar"
      )
    else
      psychologist_path(
        profile,
        calendar: profile.id,
        week: params[:week],
        anchor: "psychologist-#{profile.id}-calendar"
      )
    end
  end
end
