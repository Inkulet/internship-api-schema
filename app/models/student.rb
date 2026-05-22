require "digest"

class Student < ApplicationRecord
  belongs_to :school
  belongs_to :school_class,
             foreign_key: :class_id,
             counter_cache: :students_count,
             inverse_of: :students

  validates :first_name, :last_name, :surname, presence: true
  validate  :school_matches_class

  after_create :assign_auth_token

  def regenerate_auth_token!
    update_column(:auth_token, build_auth_token)
  end

  def to_api_hash
    {
      id: id,
      first_name: first_name,
      last_name: last_name,
      surname: surname,
      class_id: class_id,
      school_id: school_id
    }
  end

  private

  def school_matches_class
    return if school_class.nil? || school_id.nil?
    return if school_class.school_id == school_id

    errors.add(:class_id, "не принадлежит указанной школе")
  end

  def assign_auth_token
    update_column(:auth_token, build_auth_token)
  end

  def build_auth_token
    Digest::SHA256.hexdigest("#{id}#{ENV.fetch('SECRET_SALT', 'dev-salt')}")
  end
end
