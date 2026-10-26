class PsychologistsController < ApplicationController
  def index
    @psychologists = PsychologistProfile.approved.includes(:user)

    return unless params[:sort] == "soonest"

    nearest_available_slot = Slot
                               .left_outer_joins(:appointment)
                               .where("slots.psychologist_id = psychologist_profiles.id")
                               .where("slots.start_time > ?", Time.current)
                               .where(appointments: { id: nil })
                               .select("MIN(slots.start_time)")

    @psychologists = @psychologists.order(
      Arel.sql("(#{nearest_available_slot.to_sql}) ASC NULLS LAST")
    )
  end

  def show
    @psychologist = PsychologistProfile.approved
                                       .includes(:user, slots: :appointment)
                                       .find_by(id: params[:id])

    return head :not_found unless @psychologist

    @week_offset = params.fetch(:week, "0").to_i.clamp(0, 52)
    week_start = calendar_week_start(@week_offset)

    @calendar_days = (0..4).map { |offset| week_start + offset.days }

    week_end = (@calendar_days.last + 1.day).beginning_of_day

    visible_slots = @psychologist.slots
                                 .includes(:appointment)
                                 .where(
                                   start_time: @calendar_days.first.beginning_of_day...week_end
                                 )
                                 .where("slots.start_time > ?", Time.current)
                                 .order(:start_time)

    @slots_by_profile_and_date = {
      @psychologist.id => visible_slots.group_by { |slot| slot.start_time.to_date }
    }
  end
end
