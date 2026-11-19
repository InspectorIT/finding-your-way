class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :psychologist_profile

  before_validation :mark_verified_client, on: :create

  validates :body,
            presence: true,
            length: { maximum: 2_000 }

  validate :author_must_have_appointment, on: :create

  after_create_commit :broadcast_created_comment
  after_update_commit :broadcast_updated_comment
  after_destroy_commit :broadcast_destroyed_comment

  private

  def appointments_with_psychologist
    return Appointment.none if user_id.blank? || psychologist_profile_id.blank?

    Appointment.joins(:slot)
               .where(client_id: user_id)
               .where(slots: { psychologist_id: psychologist_profile_id })
  end

  def author_must_have_appointment
    return if appointments_with_psychologist.exists?

    errors.add(
      :base,
      "Оставить комментарий можно только при наличии записи к этому психологу."
    )
  end

  def mark_verified_client
    self.verified_client =
      appointments_with_psychologist
        .where("slots.end_time <= ?", Time.current)
        .exists?
  end

  def broadcast_created_comment
    broadcast_remove_to(
      psychologist_profile,
      :comments,
      target: "comments_empty"
    )

    broadcast_prepend_to(
      psychologist_profile,
      :comments,
      target: "comments_list",
      partial: "comments/comment",
      locals: { comment: self, show_actions: true }
    )
  end

  def broadcast_updated_comment
    broadcast_replace_to(
      psychologist_profile,
      :comments,
      target: "comment_content_#{id}",
      partial: "comments/comment_content",
      locals: { comment: self }
    )
  end

  def broadcast_destroyed_comment
    profile = PsychologistProfile.find_by(id: psychologist_profile_id)
    return unless profile

    broadcast_remove_to(
      profile,
      :comments,
      target: "comment_#{id}"
    )

    return if profile.comments.exists?

    broadcast_append_to(
      profile,
      :comments,
      target: "comments_list",
      partial: "comments/empty"
    )
  end
end
