class Slot < ApplicationRecord
  belongs_to :psychologist_profile,
             foreign_key: :psychologist_id

  has_one :appointment, dependent: :restrict_with_error

  after_update_commit :broadcast_slot_update
  after_destroy_commit :broadcast_slot_removal

  validates :start_time, :end_time, presence: true

  validate :end_time_after_start_time
  validate :start_time_must_be_in_future
  validate :slot_must_not_overlap_other_slots

  private

  # Потому что, например, слот 15:00–14:00 не имеет смысла
  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    return if end_time > start_time

    errors.add(:end_time, "должно быть позже времени начала")
  end

  def start_time_must_be_in_future
    return if start_time.blank?
    return if start_time > Time.current

    errors.add(:start_time, "должно быть в будущем")
  end

  def slot_must_not_overlap_other_slots
    return if start_time.blank? || end_time.blank?
    return if psychologist_profile.nil?

    slots = psychologist_profile.slots
    slots = slots.where.not(id: id) if persisted?

    overlapping = slots.where(
      "start_time < ? AND end_time > ?",
      end_time,
      start_time
    ).exists?

    errors.add(:base, "Время пересекается с другим слотом") if overlapping
  end

  def broadcast_slot_update
    return broadcast_available_slot unless saved_change_to_start_time?

    previous_start_time = saved_change_to_start_time.first
    previous_date = previous_start_time.to_date
    current_date = start_time.to_date

    broadcast_remove_slot

    if previous_date != current_date
      broadcast_empty_day(previous_date)

      broadcast_remove_to(
        psychologist_profile,
        :availability,
        target: empty_day_dom_id(current_date)
      )
    end

    broadcast_insert_slot
  end

  def broadcast_available_slot
    broadcast_replace_to(
      psychologist_profile,
      :availability,
      target: slot_dom_id,
      partial: "psychologists/available_slot",
      locals: { slot: self }
    )
  end

  def broadcast_slot_removal
    broadcast_remove_slot
    broadcast_empty_day(start_time.to_date)
  end

  def broadcast_remove_slot
    broadcast_remove_to(
      psychologist_profile,
      :availability,
      target: slot_dom_id
    )
  end

  def broadcast_insert_slot
    next_slot = psychologist_profile.slots
                                    .where(start_time: start_time.to_date.all_day)
                                    .where("slots.start_time > ?", start_time)
                                    .order(:start_time)
                                    .first

    rendering = {
      partial: "psychologists/available_slot",
      locals: { slot: self }
    }

    if next_slot
      broadcast_before_to(
        psychologist_profile,
        :availability,
        target: "slot_#{next_slot.id}",
        **rendering
      )
    else
      broadcast_append_to(
        psychologist_profile,
        :availability,
        target: calendar_day_dom_id(start_time.to_date),
        **rendering
      )
    end
  end

  def broadcast_empty_day(date)
    remaining_slots = psychologist_profile.slots
                                          .where(start_time: date.all_day)
                                          .where("slots.start_time > ?", Time.current)

    return if remaining_slots.exists?

    broadcast_append_to(
      psychologist_profile,
      :availability,
      target: calendar_day_dom_id(date),
      partial: "psychologists/empty_day_slots",
      locals: {
        profile: psychologist_profile,
        day: date
      }
    )
  end

  def slot_dom_id
    "slot_#{id}"
  end

  def calendar_day_dom_id(date)
    "psychologist_#{psychologist_id}_slots_#{date.iso8601}"
  end

  def empty_day_dom_id(date)
    "empty_#{calendar_day_dom_id(date)}"
  end
end
