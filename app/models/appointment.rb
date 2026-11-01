class Appointment < ApplicationRecord
  belongs_to :client, class_name: "User"
  belongs_to :slot

  validates :slot_id, uniqueness: true

  after_create_commit :broadcast_slot_booking

  private

  def broadcast_slot_booking
    slot.broadcast_replace_to(
      slot.psychologist_profile,
      :availability,
      partial: "psychologists/booked_slot",
      locals: { slot: slot }
    )
  end
end
