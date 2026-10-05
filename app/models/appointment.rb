class Appointment < ApplicationRecord
  belongs_to :client, class_name: "User"
  belongs_to :slot

  enum :status, {
    pending: 0,
    confirmed: 1
  }

  validates :slot_id, uniqueness: true
end
