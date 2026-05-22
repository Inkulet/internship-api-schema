class SchoolClass < ApplicationRecord
  self.table_name = "classes"

  belongs_to :school
  has_many :students, foreign_key: :class_id, dependent: :destroy, inverse_of: :school_class

  validates :number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :letter, presence: true
  validates :letter, uniqueness: { scope: [:school_id, :number] }

  def to_api_hash
    {
      id: id,
      number: number,
      letter: letter,
      students_count: students_count
    }
  end
end
