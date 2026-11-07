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

  after_create_commit :enqueue_booking_notification

  after_update_commit :enqueue_reschedule_notifications,
                      if: :saved_change_to_slot_id?

  before_destroy :capture_cancellation_notification

  after_destroy_commit :enqueue_cancellation_notification

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

  def enqueue_booking_notification
    current_slot = notification_slot
    return unless current_slot

    notification = notification_payload(current_slot)

    return if notification[:psychologist_email].blank?

    AppointmentMailer.with(notification: notification)
                     .booking_created
                     .deliver_later
  end

  def capture_cancellation_notification
    released_slot = notification_slot
    return unless released_slot

    @cancellation_notification = notification_payload(released_slot)
  end

  def enqueue_cancellation_notification
    notification = @cancellation_notification
    return unless notification
    return if notification[:psychologist_email].blank?

    AppointmentMailer.with(notification: notification)
                     .booking_cancelled
                     .deliver_later
  end

  def enqueue_reschedule_notifications
    previous_slot_id, = saved_change_to_slot_id

    previous_slot = notification_slot(previous_slot_id)
    current_slot = notification_slot

    return unless previous_slot && current_slot

    if previous_slot.psychologist_id == current_slot.psychologist_id
      notification = notification_payload(current_slot)

      previous_start = previous_slot.start_time.in_time_zone
      previous_end = previous_slot.end_time.in_time_zone

      notification.merge!(
        previous_date: previous_start.strftime("%d.%m.%Y"),
        previous_start_time: previous_start.strftime("%H:%M"),
        previous_end_time: previous_end.strftime("%H:%M")
      )

      AppointmentMailer.with(notification: notification)
                       .booking_rescheduled
                       .deliver_later
    else
      old_notification = notification_payload(previous_slot)
      new_notification = notification_payload(current_slot)

      AppointmentMailer.with(notification: old_notification)
                       .booking_cancelled
                       .deliver_later

      AppointmentMailer.with(notification: new_notification)
                       .booking_created
                       .deliver_later
    end
  end

  def notification_slot(id = slot_id)
    Slot.includes(psychologist_profile: :user).find_by(id: id)
  end

  def notification_payload(slot_record)
    profile = slot_record.psychologist_profile

    start_time = slot_record.start_time.in_time_zone
    end_time = slot_record.end_time.in_time_zone

    {
      psychologist_email: profile.user.email,
      psychologist_name: profile.user.name,
      client_name: client.name,
      specialization: profile.specialization,
      date: start_time.strftime("%d.%m.%Y"),
      start_time: start_time.strftime("%H:%M"),
      end_time: end_time.strftime("%H:%M")
    }
  end
end
