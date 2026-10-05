class Slot < ApplicationRecord
  belongs_to :psychologist_profile,
             foreign_key: :psychologist_id

  has_one :appointment, dependent: :restrict_with_error

  validates :start_time, :end_time, presence: true

  validate :end_time_after_start_time

  private

  # Потому что, например, слот 15:00–14:00 не имеет смысла
  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    return if end_time > start_time

    errors.add(:end_time, "должно быть позже времени начала")
  end
end
