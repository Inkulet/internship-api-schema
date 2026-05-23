require "digest"

class Student < ApplicationRecord
  belongs_to :school
  # foreign_key :class_id, потому что колонка в БД называется class_id (по openapi),
  # а не school_class_id (как требует convention Rails).
  # counter_cache держит students_count в classes актуальным без COUNT(*) на чтении.
  belongs_to :school_class,
             foreign_key: :class_id,
             counter_cache: :students_count,
             inverse_of: :students

  validates :first_name, :last_name, :surname, presence: true
  validates :class_id, :school_id,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true
  validate  :school_matches_class

  # Токен генерируется ПОСЛЕ создания, потому что хэш привязан к id, который
  # известен только после INSERT. update_column минует валидации и не плодит
  # лишний updated_at — пишем напрямую.
  after_create :assign_auth_token

  def regenerate_auth_token!
    update_column(:auth_token, build_auth_token)
  end

  # Возвращает JSON-представление студента по схеме openapi.
  # Намеренно НЕ включает auth_token и timestamps.
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

    # Символьный ключ — текст берётся из config/locales/ru.yml
    # (errors.models.student.attributes.class_id.foreign_class).
    errors.add(:class_id, :foreign_class)
  end

  def assign_auth_token
    update_column(:auth_token, build_auth_token)
  end

  def build_auth_token
    Digest::SHA256.hexdigest("#{id}#{self.class.secret_salt}")
  end

  # Источник секретной соли — приоритеты:
  #   1) ENV["SECRET_SALT"]                          (для деплоя/CI)
  #   2) Rails.application.credentials.secret_salt   (Rails-идиоматичный путь)
  #   3) "dev-salt"                                  (только dev/test)
  # В production без п. 1 или п. 2 — падаем сразу, чтобы не сгенерировать
  # предсказуемые токены от дефолтной соли.
  def self.secret_salt
    ENV["SECRET_SALT"].presence ||
      Rails.application.credentials.secret_salt.presence ||
      if Rails.env.development? || Rails.env.test?
        "dev-salt"
      else
        raise KeyError, "SECRET_SALT не задан (требуется в production)"
      end
  end
end
