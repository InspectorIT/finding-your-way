require "test_helper"

class CommentTest < ActiveSupport::TestCase
  # Комментарий с будущей записью допустим,
  # но автор ещё не считается подтверждённым клиентом.
  test "valid comment with future appointment" do
    client = create_client
    profile = create_psychologist_profile
    create_appointment(client: client, profile: profile)

    comment = build_comment(client: client, profile: profile)

    assert comment.valid?
    assert_not comment.verified_client?
    assert_not comment.anonymous?
  end

  # Завершённый сеанс даёт отметку подтверждённого клиента.
  test "marks client as verified when appointment is completed" do
    client = create_client
    profile = create_psychologist_profile

    create_appointment(
      client: client,
      profile: profile,
      completed: true
    )

    comment = build_comment(client: client, profile: profile)

    assert comment.save
    assert comment.verified_client?
  end

  # Пользователь не может самостоятельно установить отметку.
  test "does not allow client to assign verified status manually" do
    client = create_client
    profile = create_psychologist_profile
    create_appointment(client: client, profile: profile)

    comment = build_comment(
      client: client,
      profile: profile,
      verified_client: true
    )

    assert comment.valid?
    assert_not comment.verified_client?
  end

  # Без записи к психологу оставить комментарий нельзя.
  test "is invalid without appointment" do
    client = create_client
    profile = create_psychologist_profile

    comment = build_comment(client: client, profile: profile)

    assert_not comment.valid?
    assert_includes comment.errors.attribute_names, :base
  end

  # Запись к другому психологу не даёт права комментировать.
  test "is invalid when appointment belongs to another psychologist" do
    client = create_client

    first_profile = create_psychologist_profile(
      email: "first-psychologist@example.com"
    )

    second_profile = create_psychologist_profile(
      email: "second-psychologist@example.com"
    )

    create_appointment(
      client: client,
      profile: first_profile
    )

    comment = build_comment(
      client: client,
      profile: second_profile
    )

    assert_not comment.valid?
    assert_includes comment.errors.attribute_names, :base
  end

  # Текст комментария обязателен.
  test "is invalid without body" do
    client = create_client
    profile = create_psychologist_profile
    create_appointment(client: client, profile: profile)

    comment = build_comment(
      client: client,
      profile: profile,
      body: ""
    )

    assert_not comment.valid?
    assert_includes comment.errors.attribute_names, :body
  end

  # Ровно 2000 символов разрешены.
  test "is valid with body containing 2000 characters" do
    client = create_client
    profile = create_psychologist_profile
    create_appointment(client: client, profile: profile)

    comment = build_comment(
      client: client,
      profile: profile,
      body: "А" * 2000
    )

    assert comment.valid?
  end

  # Более 2000 символов запрещено.
  test "is invalid when body exceeds 2000 characters" do
    client = create_client
    profile = create_psychologist_profile
    create_appointment(client: client, profile: profile)

    comment = build_comment(
      client: client,
      profile: profile,
      body: "А" * 2001
    )

    assert_not comment.valid?
    assert_includes comment.errors.attribute_names, :body
  end

  # Анонимность не отменяет проверку записи.
  # Настоящий автор сохраняется в user_id.
  test "allows anonymous comment while preserving its author" do
    client = create_client
    profile = create_psychologist_profile
    create_appointment(client: client, profile: profile)

    comment = build_comment(
      client: client,
      profile: profile,
      anonymous: true
    )

    assert comment.save
    assert comment.anonymous?
    assert_not comment.verified_client?
    assert_equal client, comment.user
  end

  # Подтверждение не должно появляться задним числом.
  test "does not become verified after appointment is completed later" do
    client = create_client
    profile = create_psychologist_profile

    appointment = create_appointment(
      client: client,
      profile: profile
    )

    comment = build_comment(client: client, profile: profile)
    comment.save!

    appointment.slot.update_columns(
      start_time: 2.hours.ago,
      end_time: 1.hour.ago
    )

    assert_not comment.reload.verified_client?
  end

  private

  def create_client
    User.create!(
      email: "comment-client@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Клиент",
      phone: "+79991112233",
      role: :client
    )
  end

  def create_psychologist_profile(email: "comment-psychologist@example.com")
    user = User.create!(
      email: email,
      password: "password123",
      password_confirmation: "password123",
      name: "Анна Петрова",
      phone: "+79992223344",
      role: :psychologist
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

  def create_appointment(client:, profile:, completed: false)
    start_time = 1.day.from_now

    slot = profile.slots.create!(
      start_time: start_time,
      end_time: start_time + profile.session_duration.minutes
    )

    if completed
      slot.update_columns(
        start_time: 2.hours.ago,
        end_time: 1.hour.ago
      )
    end

    Appointment.create!(
      client: client,
      slot: slot
    )
  end

  def build_comment(client:, profile:, body: "Хороший специалист!",
                    anonymous: false, verified_client: false)
    profile.comments.new(
      user: client,
      body: body,
      anonymous: anonymous,
      verified_client: verified_client
    )
  end
end
