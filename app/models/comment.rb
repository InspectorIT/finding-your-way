class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :psychologist_profile

  validates :body,
            presence: true,
            length: { maximum: 2_000 }
end
