require "test_helper"
require "turbo/broadcastable/test_helper"

class LiveSlotUpdatesTest < ActionDispatch::IntegrationTest
  # after_create_commit должен выполниться после настоящего commit.
  # Поэтому отключаем общую тестовую транзакцию и чистим данные вручную.
  self.use_transactional_tests = false

  include Turbo::Broadcastable::TestHelper

  PASSWORD = "password123"

  PSYCHOLOGIST_EMAIL = "live-psychologist@example.com"
  OTHER_PSYCHOLOGIST_EMAIL = "other-live-psychologist@example.com"
  CLIENT_EMAIL = "live-client@example.com"

  test "booking broadcasts a slot replacement to the psychologist calendar" do
    # 1. Создаём двух психологов.
    psychologist = create_user(
      email: PSYCHOLOGIST_EMAIL,
      name: "Анна Петрова",
      phone: "+79990000201",
      role: :psychologist
    )

    profile = create_profile(psychologist)

    other_psychologist = create_user(
      email: OTHER_PSYCHOLOGIST_EMAIL,
      name: "Иван Иванов",
      phone: "+79990000202",
      role: :psychologist
    )

    other_profile = create_profile(other_psychologist)

    # 2. Создаём свободный слот.
    start_time = 2.days.from_now.change(
      hour: 10,
      min: 0,
      sec: 0,
      usec: 0
    )

    slot = profile.slots.create!(
      start_time: start_time,
      end_time: start_time + 50.minutes
    )

    # 3. Создаём клиента и авторизуем его.
    client = create_user(
      email: CLIENT_EMAIL,
      name: "Мария Клиент",
      phone: "+79990000203",
      role: :client
    )

    post auth_login_url, params: {
      email: client.email,
      password: PASSWORD
    }

    assert_redirected_to root_url

    # 4. Проверяем, что страница действительно подписана
    # на Turbo Stream и содержит нужный Turbo Frame.
    get psychologist_url(profile)

    assert_response :success
    assert_select "turbo-cable-stream-source"
    assert_select "turbo-frame#slot_#{slot.id}"

    # 5. Бронируем слот и перехватываем Turbo Stream broadcast.
    broadcasts = capture_turbo_stream_broadcasts(
      [ profile, :availability ]
    ) do
      assert_difference("Appointment.count", 1) do
        post appointments_url, params: {
          slot_id: slot.id
        }
      end
    end

    # 6. Проверяем, что отправлено ровно одно обновление.
    assert_equal 1, broadcasts.size

    broadcast = broadcasts.first

    # Проверяем тип операции и целевой HTML-элемент.
    assert_equal "replace", broadcast["action"]
    assert_equal "slot_#{slot.id}", broadcast["target"]

    # Проверяем содержимое обновлённого HTML.
    assert_includes broadcast.inner_html, "занято"
    assert_includes broadcast.inner_html, start_time.strftime("%H:%M")

    # 7. Проверяем, что бронь действительно сохранилась.
    appointment = Appointment.find_by!(slot: slot)

    assert_equal client, appointment.client
    assert_equal slot, appointment.slot

    # 8. Убедимся, что календарь другого психолога
    # не получил это обновление.
    assert_no_turbo_stream_broadcasts(
      [ other_profile, :availability ]
    )

    assert_redirected_to psychologist_url(
                           profile,
                           calendar: profile.id,
                           anchor: "psychologist-#{profile.id}-calendar"
                         )
  end

  test "editing a slot broadcasts its removal and insertion" do
    # Подготовка данных

    broadcasts = capture_turbo_stream_broadcasts(
      [profile, :availability]
    ) do
      # Запрос на редактирование слота
    end

    # Проверки broadcasts
    assert_equal %w[remove before],
                 broadcasts.map { |broadcast| broadcast["action"] }

    assert_equal "slot_#{slot.id}",
                 broadcasts.first["target"]

    assert_equal "slot_#{next_slot.id}",
                 broadcasts.last["target"]
  end

  test "deleting the last slot broadcasts empty day" do
    # Подготовка данных

    broadcasts = capture_turbo_stream_broadcasts(
      [profile, :availability]
    ) do
      # Запрос на удаление слота
    end

    assert_equal %w[remove append],
                 broadcasts.map { |broadcast| broadcast["action"] }

    assert_includes broadcasts.last.inner_html, "Нет слотов"
  end

  private

  def create_user(email:, name:, phone:, role:)
    User.create!(
      email: email,
      password: PASSWORD,
      password_confirmation: PASSWORD,
      name: name,
      phone: phone,
      role: role
    )
  end

  def create_profile(user)
    PsychologistProfile.create!(
      user: user,
      specialization: "Клиническая психология",
      experience_years: 5,
      price_per_session: 3000,
      session_duration: 50,
      bio: "Помогаю справляться с тревожностью.",
      status: :approved
    )
  end

  def teardown
    user_ids = User.where(
      email: [
        PSYCHOLOGIST_EMAIL,
        OTHER_PSYCHOLOGIST_EMAIL,
        CLIENT_EMAIL
      ]
    ).pluck(:id)

    profile_ids = PsychologistProfile.where(
      user_id: user_ids
    ).pluck(:id)

    slot_ids = Slot.where(
      psychologist_id: profile_ids
    ).pluck(:id)

    Appointment.where(slot_id: slot_ids)
               .or(Appointment.where(client_id: user_ids))
               .delete_all

    Slot.where(id: slot_ids).delete_all
    PsychologistProfile.where(id: profile_ids).delete_all
    User.where(id: user_ids).delete_all
  ensure
    super
  end
end
