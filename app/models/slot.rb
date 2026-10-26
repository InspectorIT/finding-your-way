class Slot < ApplicationRecord
  belongs_to :psychologist_profile,
             foreign_key: :psychologist_id

  has_one :appointment, dependent: :restrict_with_error

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
end
