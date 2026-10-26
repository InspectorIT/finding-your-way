require "test_helper"

class BookingHappyPathTest < ActionDispatch::IntegrationTest
  PASSWORD = "password123"

  test "user can become a psychologist and a client can book a session" do
    # 1. Регистрируем будущего психолога как обычного клиента.
    assert_difference("User.count", 1) do
      post auth_register_url, params: {
        user: {
          name: "Анна Петрова",
          phone: "+79990000101",
          email: "anna-happy-path@example.com",
          password: PASSWORD,
          password_confirmation: PASSWORD
        }
      }
    end

    psychologist = User.find_by!(
      email: "anna-happy-path@example.com"
    )

    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
    assert_predicate psychologist, :client?

    # 2. Клиент подаёт заявку на профиль психолога.
    assert_difference("PsychologistProfile.count", 1) do
      post psychologist_applications_url, params: {
        psychologist_profile: {
          specialization: "Клиническая психология",
          experience_years: 5,
          price_per_session: 3000,
          session_duration: 50,
          bio: "Помогаю справляться с тревожностью."
        }
      }
    end

    profile = psychologist.reload.psychologist_profile

    assert_redirected_to root_url
    assert_predicate profile, :pending?
    assert_predicate psychologist, :client?

    follow_redirect!
    assert_response :success
    assert_includes response.body, "Заявка на рассмотрении"

    # 3. Администратор одобряет заявку.
    admin = create_user(
      email: "admin-happy-path@example.com",
      name: "Администратор",
      phone: "+79990000102",
      role: :admin
    )

    sign_out
    sign_in(admin)

    get admin_psychologist_applications_url

    assert_response :success
    assert_includes response.body, psychologist.name

    patch admin_psychologist_application_url(profile),
          params: { status: "approved" }

    assert_redirected_to admin_psychologist_applications_url
    assert_predicate profile.reload, :approved?
    assert_predicate psychologist.reload, :psychologist?

    # 4. Психолог входит в систему и создаёт свободный сеанс.
    sign_out
    sign_in(psychologist.reload)

    get slots_url
    assert_response :success

    start_time = future_weekday_start_time
    week_offset = calendar_week_offset_for(start_time.to_date)

    assert_difference("Slot.count", 1) do
      post slots_url, params: {
        week: week_offset,
        slot: {
          start_time: start_time.iso8601,
          end_time: (start_time + 50.minutes).iso8601
        }
      }
    end

    assert_redirected_to slots_url(week: week_offset)

    slot = profile.slots.order(:id).last
    assert_equal start_time.to_i, slot.start_time.to_i

    # 5. Второй пользователь регистрируется как клиент.
    sign_out

    assert_difference("User.count", 1) do
      post auth_register_url, params: {
        user: {
          name: "Мария Клиент",
          phone: "+79990000103",
          email: "maria-happy-path@example.com",
          password: PASSWORD,
          password_confirmation: PASSWORD
        }
      }
    end

    client = User.find_by!(
      email: "maria-happy-path@example.com"
    )

    assert_redirected_to root_url
    assert_predicate client, :client?

    follow_redirect!
    assert_response :success

    # 6. Клиент находит психолога и видит свободный слот.
    get root_url(week: week_offset)

    assert_response :success
    assert_includes response.body, psychologist.name
    assert_includes response.body, start_time.strftime("%H:%M")
    assert_select "form[action=?]", appointments_path

    get psychologist_url(profile, week: week_offset)

    assert_response :success
    assert_select "form[action=?]", appointments_path
    assert_select ".slot-item__time",
                  text: start_time.strftime("%H:%M")

    # 7. Клиент записывается на сеанс.
    assert_difference("Appointment.count", 1) do
      post appointments_url, params: {
        slot_id: slot.id,
        return_to_home: "0",
        week: week_offset
      }
    end

    appointment = Appointment.find_by!(slot: slot)

    assert_equal client, appointment.client
    assert_equal slot, appointment.slot

    assert_redirected_to psychologist_url(
                           profile,
                           calendar: profile.id,
                           week: week_offset,
                           anchor: "psychologist-#{profile.id}-calendar"
                         )

    follow_redirect!
    assert_response :success
    assert_includes response.body, "Вы записаны на сеанс."
    assert_includes response.body, "занято"

    # 8. Клиент видит запись в личном кабинете.
    get account_url

    assert_response :success
    assert_includes response.body, "Мои записи"
    assert_includes response.body, psychologist.name
    assert_includes response.body, start_time.strftime("%H:%M")

    # 9. Психолог видит записавшегося клиента.
    sign_out
    sign_in(psychologist.reload)

    get account_url

    assert_response :success
    assert_includes response.body, "Клиенты, записанные ко мне"
    assert_includes response.body, client.name

    get slots_url(week: week_offset)

    assert_response :success
    assert_includes response.body, client.name
  end

  test "client cannot create a schedule slot" do
    client = create_user(
      email: "client-no-slots@example.com",
      name: "Обычный клиент",
      phone: "+79990000104"
    )

    sign_in(client)

    start_time = future_weekday_start_time

    assert_no_difference("Slot.count") do
      post slots_url, params: {
        slot: {
          start_time: start_time.iso8601,
          end_time: (start_time + 50.minutes).iso8601
        }
      }
    end

    assert_response :forbidden
  end

  test "psychologist cannot book own slot" do
    psychologist, profile = create_approved_profile(
      email: "psychologist-self-book@example.com",
      phone: "+79990000105"
    )

    slot = create_slot(
      profile,
      start_time: future_weekday_start_time
    )

    sign_in(psychologist)

    assert_no_difference("Appointment.count") do
      post appointments_url, params: { slot_id: slot.id }
    end

    assert_redirected_to psychologist_url(profile)

    follow_redirect!
    assert_response :success
    assert_includes response.body, "Нельзя записаться на собственный сеанс."
    assert_nil slot.reload.appointment
  end

  test "client cannot book an already occupied slot" do
    _psychologist, profile = create_approved_profile(
      email: "psychologist-occupied@example.com",
      phone: "+79990000106"
    )

    slot = create_slot(
      profile,
      start_time: future_weekday_start_time
    )

    first_client = create_user(
      email: "first-client@example.com",
      name: "Первый клиент",
      phone: "+79990000107"
    )

    second_client = create_user(
      email: "second-client@example.com",
      name: "Второй клиент",
      phone: "+79990000108"
    )

    original_appointment = Appointment.create!(
      client: first_client,
      slot: slot
    )

    sign_in(second_client)

    assert_no_difference("Appointment.count") do
      post appointments_url, params: { slot_id: slot.id }
    end

    assert_redirected_to psychologist_url(
                           profile,
                           calendar: profile.id,
                           anchor: "psychologist-#{profile.id}-calendar"
                         )

    follow_redirect!
    assert_response :success
    assert_includes response.body, "Этот слот уже недоступен."

    assert_equal original_appointment, slot.reload.appointment
    assert_equal first_client, slot.appointment.client
  end

  private

  def sign_in(user)
    post auth_login_url, params: {
      email: user.email,
      password: PASSWORD
    }

    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
  end

  def sign_out
    delete auth_logout_url

    assert_redirected_to root_url
    follow_redirect!
    assert_response :success
  end

  def create_user(email:, name:, phone:, role: :client)
    User.create!(
      email: email,
      password: PASSWORD,
      password_confirmation: PASSWORD,
      name: name,
      phone: phone,
      role: role
    )
  end

  def create_approved_profile(email:, phone:)
    psychologist = create_user(
      email: email,
      name: "Тестовый психолог",
      phone: phone,
      role: :psychologist
    )

    profile = PsychologistProfile.create!(
      user: psychologist,
      specialization: "Клиническая психология",
      experience_years: 5,
      price_per_session: 3000,
      session_duration: 50,
      bio: "Помогаю справляться с тревожностью.",
      status: :approved
    )

    [ psychologist, profile ]
  end

  def create_slot(profile, start_time:)
    profile.slots.create!(
      start_time: start_time,
      end_time: start_time + profile.session_duration.minutes
    )
  end

  def future_weekday_start_time
    date = Time.zone.today + 1.day
    date += 1.day while date.saturday? || date.sunday?

    Time.zone.local(date.year, date.month, date.day, 10, 0, 0)
  end

  def calendar_week_offset_for(date)
    today = Time.zone.today
    week_start = today.beginning_of_week
    week_start += 1.week if week_start + 4.days < today

    ((date.beginning_of_week - week_start) / 7).to_i
  end
end
