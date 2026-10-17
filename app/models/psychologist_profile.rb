class PsychologistProfile < ApplicationRecord
  belongs_to :user
  has_many :slots, foreign_key: :psychologist_id, dependent: :destroy

  enum :status, {
    pending: 0,
    approved: 1,
    rejected: 2
  }

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
