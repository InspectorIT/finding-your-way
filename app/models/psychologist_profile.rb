class PsychologistProfile < ApplicationRecord
  PHOTO_CONTENT_TYPES = %w[
    image/jpeg
    image/png
    image/webp
  ].freeze

  MAX_PHOTO_SIZE = 5.megabytes

  belongs_to :user
  has_many :slots, foreign_key: :psychologist_id, dependent: :destroy
  has_one_attached :photo

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

  validate :validate_photo

  private

  def validate_photo
    return unless photo.attached?

    unless PHOTO_CONTENT_TYPES.include?(photo.blob.content_type)
      errors.add(
        :photo,
        "должна быть в формате JPG, PNG или WEBP"
      )
    end

    if photo.blob.byte_size > MAX_PHOTO_SIZE
      errors.add(:photo, "не должна превышать 5 МБ")
    end
  end
end
