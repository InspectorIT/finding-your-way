# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require "zlib"

# Демо-данные предназначены только для локальной разработки.
if Rails.env.development?
  demo_password = "DemoPassword123!"

  # Тестовый клиент — для проверки бронирования.
  client = User.find_or_initialize_by(email: "demo.client@example.com")
  client.assign_attributes(
    name: "Тестовый Клиент",
    phone: "+79990000001",
    role: :client
  )
  client.password = demo_password
  client.password_confirmation = demo_password
  client.save!

  psychologists_data = [
    {
      email: "anna.petrova@example.com",
      name: "Анна Петрова",
      phone: "+79990000002",
      specialization: "Тревожность, стресс и КПТ",
      experience_years: 8,
      price_per_session: 3500,
      session_duration: 50,
      bio: "Помогаю справляться с тревогой, хроническим стрессом " \
        "и чрезмерной самокритикой. На встречах вместе определяем " \
        "цели и подбираем практические упражнения."
    },
    {
      email: "mikhail.lebedev@example.com",
      name: "Михаил Лебедев",
      phone: "+79990000003",
      specialization: "Отношения и семейная психология",
      experience_years: 11,
      price_per_session: 4500,
      session_duration: 60,
      bio: "Работаю с трудностями в отношениях, конфликтами и " \
        "личными границами. Помогаю лучше понимать свои потребности " \
        "и выстраивать открытый диалог."
    },
    {
      email: "elena.morozova@example.com",
      name: "Елена Морозова",
      phone: "+79990000004",
      specialization: "Самооценка и личные границы",
      experience_years: 6,
      price_per_session: 3200,
      session_duration: 50,
      bio: "Помогаю укреплять самооценку, отстаивать личные границы " \
        "и уменьшать чувство вины. Работаем в комфортном темпе, " \
        "опираясь на ваши запросы."
    },
    {
      email: "dmitry.smirnov@example.com",
      name: "Дмитрий Смирнов",
      phone: "+79990000005",
      specialization: "Выгорание и профессиональный стресс",
      experience_years: 9,
      price_per_session: 4000,
      session_duration: 50,
      bio: "Работаю с эмоциональным выгоранием, переутомлением " \
        "и сложностями в профессиональной сфере. Помогаю находить " \
        "более устойчивый баланс между работой и отдыхом."
    },
    {
      email: "maria.volkova@example.com",
      name: "Мария Волкова",
      phone: "+79990000006",
      specialization: "Жизненные перемены и поиск себя",
      experience_years: 7,
      price_per_session: 3800,
      session_duration: 60,
      bio: "Поддерживаю во время жизненных перемен, переезда, " \
        "смены профессии и поиска новых ориентиров. Вместе " \
        "разбираемся в ценностях и возможных направлениях."
    },
    {
      email: "alexandra.sokolova@example.com",
      name: "Александра Соколова",
      phone: "+79990000007",
      specialization: "Эмоциональная устойчивость и утрата",
      experience_years: 12,
      price_per_session: 5000,
      session_duration: 50,
      bio: "Бережно работаю с переживанием утраты, сильными эмоциями " \
        "и трудными периодами жизни. Создаю пространство, " \
        "в котором можно безопасно говорить о сложном."
    }
  ]

  psychologists_data.each do |data|
    user = User.find_or_initialize_by(email: data[:email])
    user.assign_attributes(
      name: data[:name],
      phone: data[:phone],
      role: :psychologist
    )

    if user.new_record?
      user.password = demo_password
      user.password_confirmation = demo_password
    end

    user.save!

    profile = PsychologistProfile.find_or_initialize_by(user: user)
    profile.assign_attributes(
      specialization: data[:specialization],
      experience_years: data[:experience_years],
      price_per_session: data[:price_per_session],
      session_duration: data[:session_duration],
      bio: data[:bio],
      status: :approved
    )
    profile.save!

    # Создаём расписание на текущую и следующие три недели.
    # Случайный выбор воспроизводим: повторный запуск не меняет расписание.
    first_week = Date.current.beginning_of_week

    4.times do |week_offset|
      week_start = first_week + week_offset.weeks

      weekdays = (0..4).map do |day_offset|
        week_start + day_offset.days
      end.select { |date| date >= Date.current }

      next if weekdays.empty?

      week_rng = Random.new(
        Zlib.crc32("#{user.email}:#{week_start}")
      )

      active_days = weekdays.sample(
        [ 4, weekdays.size ].min,
        random: week_rng
      )

      active_days.each do |date|
        day_range = date.beginning_of_day..date.end_of_day

        # Если на этот день у специалиста уже есть слоты,
        # не добавляем новые при повторном запуске.
        next if profile.slots.where(start_time: day_range).exists?

        day_rng = Random.new(
          Zlib.crc32("#{user.email}:#{date}:slots")
        )
        target_count = day_rng.rand(1..2)
        created_count = 0

        # Встречи начинаются в случайное время с 09:00 до 17:00.
        (9..17).to_a.shuffle(random: day_rng).each do |hour|
          start_time = Time.zone.local(
            date.year, date.month, date.day, hour, 0
          )

          next if start_time <= Time.current

          end_time = start_time + profile.session_duration.minutes

          overlapping = profile.slots.where(
            "start_time < ? AND end_time > ?",
            end_time,
            start_time
          ).exists?

          next if overlapping

          profile.slots.create!(
            start_time: start_time,
            end_time: end_time
          )

          created_count += 1
          break if created_count >= target_count
        end
      end
    end

    puts "Создан или обновлён профиль: #{user.name}"
  end

  puts "Демо-данные готовы!"
  puts "Тестовый клиент: demo.client@example.com"
  puts "Пароль: #{demo_password}"
else
  puts "Демо-данные пропущены: они предназначены для development."
end
