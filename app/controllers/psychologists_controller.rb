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
                                       .includes(:user)
                                       .find_by(id: params[:id])

    return head :not_found unless @psychologist

    @available_slots = @psychologist.slots
                                    .left_outer_joins(:appointment)
                                    .where("slots.start_time > ?", Time.current)
                                    .where(appointments: { id: nil })
                                    .order(:start_time)
  end
end
