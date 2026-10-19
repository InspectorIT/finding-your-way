class HomeController < ApplicationController
  def index
    @week_offset = params.fetch(:week, "0").to_i.clamp(0, 52)
    week_start = Time.zone.today.beginning_of_week + @week_offset.weeks
    @calendar_days = (0..4).map { |offset| week_start + offset.days }

    @psychologists = PsychologistProfile.approved
                                        .includes(:user, slots: :appointment)
                                        .order(:id)

    @slots_by_profile_and_date = @psychologists.each_with_object({}) do |profile, result|
      visible_slots = profile.slots.select do |slot|
        slot.start_time > Time.current &&
          @calendar_days.include?(slot.start_time.to_date)
      end

      result[profile.id] = visible_slots.group_by do |slot|
        slot.start_time.to_date
      end
    end
  end

  def ui_kit
  end
end
