class User < ApplicationRecord
  has_secure_password

  has_one :psychologist_profile, dependent: :destroy

  has_many :appointments,
           foreign_key: :client_id,
           dependent: :destroy

  enum :role, {
    client: 0,
    psychologist: 1,
    admin: 2
  }

  validates :email,
            presence: true,
            uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :name, :phone, presence: true
end
