class PsychologistProfile < ApplicationRecord
  belongs_to :user
  has_many :slots, dependent: :destroy

  validates :specialization, :bio, presence: true

  validates :experience_years,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  validates :price_per_session,
            presence: true,
            numericality: { greater_than: 0 }

  validates :session_duration,
            presence: true,
            numericality: { greater_than: 0 }
end
