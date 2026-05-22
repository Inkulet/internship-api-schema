class School < ApplicationRecord
  has_many :school_classes, dependent: :destroy
  has_many :students, dependent: :destroy

  validates :name, presence: true
end
