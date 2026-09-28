class User < ApplicationRecord
  has_secure_password # Магия Рельсов, требующая колонку password_digest и gem bcrypt

  enum :role, { client: 0, psychologist: 1, admin: 2 }

  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, :phone, presence: true
end
