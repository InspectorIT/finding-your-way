class User < ApplicationRecord
  # Devise модули
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Ассоциации (пока закомментированы, раскомментирую когда будут созданы эти модели)
  # has_one :psychologist_profile, dependent: :destroy
  # has_many :appointments, foreign_key: :client_id, dependent: :destroy

  # Роли по умолчанию (client = 0)
  enum :role, { client: 0, psychologist: 1, admin: 2 }, default: :client

  # Валидации
  validates :name, :phone, presence: true
end