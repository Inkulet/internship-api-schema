# Seed-данные: пара школ, в каждой — несколько классов и учеников.
# Идемпотентно — повторный запуск ничего не дублирует.

ActiveRecord::Base.transaction do
  schools_data = [
    {
      name: "Школа №1 им. А.С. Пушкина",
      classes: {
        [1, "А"] => [
          ["Иван",   "Иванов",   "Иванович"],
          ["Пётр",   "Петров",   "Петрович"],
          ["Мария",  "Сидорова", "Алексеевна"]
        ],
        [1, "Б"] => [
          ["Анна",   "Смирнова", "Сергеевна"],
          ["Дмитрий", "Кузнецов", "Олегович"]
        ],
        [5, "А"] => [
          ["Алексей", "Морозов",  "Игоревич"],
          ["Ольга",   "Лебедева", "Андреевна"]
        ]
      }
    },
    {
      name: "Гимназия №2",
      classes: {
        [3, "В"] => [
          ["Никита",  "Соколов",  "Артёмович"],
          ["Виктория", "Орлова",  "Денисовна"]
        ],
        [9, "Б"] => [
          ["Артур",   "Волков",   "Максимович"]
        ]
      }
    }
  ]

  schools_data.each do |school_attrs|
    school = School.find_or_create_by!(name: school_attrs[:name])

    school_attrs[:classes].each do |(number, letter), students|
      klass = school.school_classes.find_or_create_by!(number: number, letter: letter)

      students.each do |(first_name, last_name, surname)|
        next if klass.students.exists?(first_name: first_name, last_name: last_name, surname: surname)

        Student.create!(
          school: school,
          school_class: klass,
          first_name: first_name,
          last_name: last_name,
          surname: surname
        )
      end
    end
  end
end

puts "Seeded: schools=#{School.count}, classes=#{SchoolClass.count}, students=#{Student.count}"
