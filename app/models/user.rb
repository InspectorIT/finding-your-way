class User < ApplicationRecord
  has_secure_password

  has_one :psychologist_profile, dependent: :destroy

  has_many :appointments,
           foreign_key: :client_id,
           dependent: :destroy

  enum :role, {
    client: "client",
    psychologist: "psychologist",
    admin: "admin"
  }

  validates :email,
            presence: true,
            uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :name, :phone, presence: true
end
