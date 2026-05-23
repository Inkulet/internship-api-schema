class SchoolClass < ApplicationRecord
  # `Class` зарезервировано в Ruby, поэтому модель называется SchoolClass.
  # Таблица в БД — `classes`, как и в URL openapi (/schools/:id/classes).
  self.table_name = "classes"

  belongs_to :school
  has_many :students, foreign_key: :class_id, dependent: :destroy, inverse_of: :school_class

  validates :number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :letter, presence: true
  # Дублирует unique-индекс на уровне приложения — для понятной ошибки
  # на 405 Invalid input при попытке создать второй «1А» в школе.
  validates :letter, uniqueness: { scope: [ :school_id, :number ] }

  def to_api_hash
    {
      id: id,
      number: number,
      letter: letter,
      students_count: students_count
    }
  end
end
