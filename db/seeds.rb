# db/seeds.rb

User.destroy_all

puts "Создаем 5 обычных пациентов..."
5.times do |i|
  User.create!(
    name: "Пациент #{i+1}",
    email: "client#{i+1}@example.com",
    phone: "+7900111220#{i+1}",
    password: "password123",
    is_client: true,
    is_psychologist: false
  )
end

puts "Создаем 3 чистых психологов..."
3.times do |i|
  User.create!(
    name: "Психолог #{i+1}",
    email: "psychologist#{i+1}@example.com",
    phone: "+7900333440#{i+1}",
    password: "password123",
    is_client: false,
    is_psychologist: true
  )
end

puts "Создаем 2 психологов, которые также являются пациентами..."
2.times do |i|
  User.create!(
    name: "Психолог-Пациент #{i+1}",
    email: "psy_and_client#{i+1}@example.com",
    phone: "+7900555660#{i+1}",
    password: "password123",
    is_client: true,
    is_psychologist: true
  )
end

puts "Готово! Создано #{User.count} пользователей."