class Appointment < ApplicationRecord
  belongs_to :client, class_name: "User"
  belongs_to :slot

  validates :slot_id, uniqueness: true
end
