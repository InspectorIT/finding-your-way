require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  test "client can create a comment" do
    profile = create_profile
    client = create_user("client@example.com", :client)

    sign_in(client)

    assert_difference("Comment.count", 1) do
      post psychologist_comments_url(profile), params: {
        comment: { body: "Очень хороший специалист!" }
      }
    end

    comment = Comment.order(:id).last

    assert_equal client, comment.user
    assert_equal profile, comment.psychologist_profile
    assert_equal "Очень хороший специалист!", comment.body

    assert_redirected_to psychologist_url(profile, anchor: "comments")
  end

  test "psychologist cannot create a comment" do
    profile = create_profile
    sign_in(profile.user)

    assert_no_difference("Comment.count") do
      post psychologist_comments_url(profile), params: {
        comment: { body: "Комментарий психолога" }
      }
    end

    assert_response :forbidden
  end

  test "client can update own comment" do
    profile = create_profile
    client = create_user("client@example.com", :client)

    comment = profile.comments.create!(
      user: client,
      body: "Старый комментарий"
    )

    sign_in(client)

    patch psychologist_comment_url(profile, comment), params: {
      comment: { body: "Обновлённый комментарий" }
    }

    assert_equal "Обновлённый комментарий", comment.reload.body
    assert_redirected_to psychologist_url(profile, anchor: "comments")
  end

  test "client can delete own comment" do
    profile = create_profile
    client = create_user("client@example.com", :client)

    comment = profile.comments.create!(
      user: client,
      body: "Комментарий для удаления"
    )

    sign_in(client)

    assert_difference("Comment.count", -1) do
      delete psychologist_comment_url(profile, comment)
    end

    assert_redirected_to psychologist_url(profile, anchor: "comments")
  end

  test "client cannot update another client's comment" do
    profile = create_profile

    author = create_user("author@example.com", :client)
    another_client = create_user("another@example.com", :client)

    comment = profile.comments.create!(
      user: author,
      body: "Комментарий автора"
    )

    sign_in(another_client)

    patch psychologist_comment_url(profile, comment), params: {
      comment: { body: "Попытка изменить чужой комментарий" }
    }

    assert_response :not_found
    assert_equal "Комментарий автора", comment.reload.body
  end

  test "client cannot delete another client's comment" do
    profile = create_profile

    author = create_user("author@example.com", :client)
    another_client = create_user("another@example.com", :client)

    comment = profile.comments.create!(
      user: author,
      body: "Комментарий автора"
    )

    sign_in(another_client)

    assert_no_difference("Comment.count") do
      delete psychologist_comment_url(profile, comment)
    end

    assert_response :not_found
    assert Comment.exists?(comment.id)
  end

  test "unauthorized visitor cannot create a comment" do
    profile = create_profile

    assert_no_difference("Comment.count") do
      post psychologist_comments_url(profile), params: {
        comment: { body: "Анонимный комментарий" }
      }
    end

    assert_redirected_to auth_login_url
  end

  private

  def sign_in(user)
    post auth_login_url, params: {
      email: user.email,
      password: "password123"
    }

    assert_redirected_to root_url
  end

  def create_user(email, role)
    User.create!(
      email: email,
      password: "password123",
      password_confirmation: "password123",
      name: email.split("@").first,
      phone: "+79990000001",
      role: role
    )
  end

  def create_profile
    user = create_user(
      "psychologist@example.com",
      :psychologist
    )

    PsychologistProfile.create!(
      user: user,
      specialization: "Клиническая психология",
      experience_years: 5,
      price_per_session: 3000,
      session_duration: 50,
      bio: "Описание психолога.",
      status: :approved
    )
  end
end
