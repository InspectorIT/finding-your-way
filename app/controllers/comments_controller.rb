class CommentsController < ApplicationController
  before_action :ensure_logged_in
  before_action :set_psychologist
  before_action :ensure_client, only: :create
  before_action :set_comment, only: %i[edit update destroy]

  def create
    @comment = @psychologist.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to psychologist_path(@psychologist, anchor: "comments"),
                  notice: "Комментарий успешно добавлен."
    else
      redirect_to psychologist_path(@psychologist, anchor: "comments"),
                  alert: @comment.errors.full_messages.to_sentence
    end
  end

  def edit
  end

  def update
    if @comment.update(comment_params)
      redirect_to psychologist_path(@psychologist, anchor: "comments"),
                  notice: "Комментарий успешно изменён."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy!

    redirect_to psychologist_path(@psychologist, anchor: "comments"),
                notice: "Комментарий удалён."
  end

  private

  def ensure_logged_in
    return if logged_in?

    redirect_to auth_login_path,
                alert: "Войдите в аккаунт, чтобы продолжить."
  end

  def ensure_client
    return if current_user.client?

    head :forbidden
  end

  def set_psychologist
    @psychologist = PsychologistProfile.approved.find(params[:psychologist_id])
  end

  def set_comment
    # Доступ только к комментариям текущего пользователя.
    @comment = @psychologist.comments
                            .where(user_id: current_user.id)
                            .find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
