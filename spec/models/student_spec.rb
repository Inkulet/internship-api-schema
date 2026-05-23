require "rails_helper"

RSpec.describe Student do
  let(:school) { School.create!(name: "Школа") }
  let(:klass)  { school.school_classes.create!(number: 1, letter: "А") }

  def build_student(**attrs)
    Student.new({
      school: school,
      school_class: klass,
      first_name: "Иван",
      last_name: "Иванов",
      surname: "Иванович"
    }.merge(attrs))
  end

  describe "валидации" do
    it "валиден с полным набором полей" do
      expect(build_student).to be_valid
    end

    %i[first_name last_name surname].each do |field|
      it "не валиден без #{field}" do
        expect(build_student(field => nil)).not_to be_valid
      end
    end

    it "не валиден без школы" do
      expect(build_student(school: nil)).not_to be_valid
    end

    it "не валиден без класса" do
      expect(build_student(school_class: nil)).not_to be_valid
    end

    it "не валиден, если класс относится к другой школе" do
      other_school = School.create!(name: "Другая школа")
      other_klass  = other_school.school_classes.create!(number: 5, letter: "Б")
      student = build_student(school_class: other_klass)
      expect(student).not_to be_valid
      expect(student.errors[:class_id]).to include(/не принадлежит/)
    end
  end

  describe "генерация auth_token" do
    it "выставляется автоматически после create" do
      student = build_student.tap(&:save!)
      expect(student.reload.auth_token).to match(/\A[a-f0-9]{64}\z/)
    end

    it "равен sha256(id + SECRET_SALT)" do
      student = build_student.tap(&:save!)
      salt    = ENV.fetch("SECRET_SALT", "dev-salt")
      expected = Digest::SHA256.hexdigest("#{student.id}#{salt}")
      expect(student.reload.auth_token).to eq(expected)
    end

    it "уникален между студентами" do
      a = build_student.tap(&:save!)
      b = build_student(first_name: "Пётр").tap(&:save!)
      expect(a.reload.auth_token).not_to eq(b.reload.auth_token)
    end
  end

  describe "counter_cache" do
    it "инкрементит students_count у класса при создании" do
      expect { build_student.save! }.to change { klass.reload.students_count }.by(1)
    end

    it "декрементит students_count при удалении" do
      student = build_student.tap(&:save!)
      expect { student.destroy }.to change { klass.reload.students_count }.by(-1)
    end
  end

  describe "to_api_hash" do
    it "возвращает только публичные поля без auth_token" do
      student = build_student.tap(&:save!)
      keys = student.to_api_hash.keys
      expect(keys).to match_array(%i[id first_name last_name surname class_id school_id])
      expect(keys).not_to include(:auth_token)
    end
  end
end
