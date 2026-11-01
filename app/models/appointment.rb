class Appointment < ApplicationRecord
  belongs_to :client, class_name: "User"
  belongs_to :slot

  validates :slot_id, uniqueness: true

  validates :client_id,
            uniqueness: {
              message: "У вас уже есть активная запись. Перенесите или отмените её."
            }

  after_create_commit :broadcast_slot_booking
  after_update_commit :broadcast_rescheduled_slots,
                      if: :saved_change_to_slot_id?
  after_destroy_commit :broadcast_slot_release

  private

  def broadcast_slot_booking
    broadcast_booked_slot(slot)
  end

  def broadcast_rescheduled_slots
    previous_slot_id, = saved_change_to_slot_id
    previous_slot = Slot.find_by(id: previous_slot_id)

    broadcast_available_slot(previous_slot) if previous_slot
    broadcast_booked_slot(slot)
  end

  def broadcast_slot_release
    broadcast_available_slot(slot)
  end

  def broadcast_booked_slot(slot_record)
    slot_record.broadcast_replace_to(
      slot_record.psychologist_profile,
      :availability,
      partial: "psychologists/booked_slot",
      locals: { slot: slot_record }
    )
  end

  def broadcast_available_slot(slot_record)
    slot_record.broadcast_replace_to(
      slot_record.psychologist_profile,
      :availability,
      partial: "psychologists/available_slot",
      locals: { slot: slot_record }
    )
  end
end
