class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :psychologist_profile

  validates :body,
            presence: true,
            length: { maximum: 2_000 }

  after_create_commit :broadcast_created_comment
  after_update_commit :broadcast_updated_comment
  after_destroy_commit :broadcast_destroyed_comment

  private

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
      locals: { comment: self }
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
