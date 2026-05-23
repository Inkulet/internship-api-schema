require "rails_helper"

# Краевые случаи, которых нет в основных request specs: длинные строки,
# юникод, гонка counter_cache при множественных создании.
RSpec.describe "Edge cases", type: :request do
  let(:school) { School.create!(name: "Школа") }
  let(:klass)  { school.school_classes.create!(number: 1, letter: "А") }

  def base_body
    {
      first_name: "Иван",
      last_name:  "Иванов",
      surname:    "Иванович",
      class_id:   klass.id,
      school_id:  school.id
    }
  end

  describe "длинные значения" do
    it "принимает имя длиной 1000 символов" do
      long_name = "А" * 1000
      post "/students", params: base_body.merge(first_name: long_name), as: :json
      expect(response).to have_http_status(:created)
      expect(json_body["first_name"].length).to eq(1000)
    end
  end

  describe "юникод" do
    it "принимает имя с эмодзи" do
      post "/students", params: base_body.merge(first_name: "Иван 🎓"), as: :json
      expect(response).to have_http_status(:created)
      expect(json_body["first_name"]).to eq("Иван 🎓")
    end

    it "принимает имя с не-ASCII (грузинский)" do
      post "/students", params: base_body.merge(first_name: "გიორგი"), as: :json
      expect(response).to have_http_status(:created)
    end
  end

  describe "крайние значения id" do
    it "DELETE с очень большим id → 400" do
      delete "/students/9999999999999", headers: { "Authorization" => "Bearer x" }
      expect(response).to have_http_status(:bad_request)
    end

    it "DELETE с отрицательным id → 400 (regex не пропускает минус)" do
      delete "/students/-1", headers: { "Authorization" => "Bearer x" }
      expect(response).to have_http_status(:bad_request)
    end

    it "DELETE с id = 0 → 400 (запись не существует)" do
      delete "/students/0", headers: { "Authorization" => "Bearer x" }
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "невалидные типы в POST body" do
    it "не падает на class_id строкой" do
      post "/students", params: base_body.merge(class_id: "abc"), as: :json
      expect(response).to have_http_status(405)
    end

    it "не падает на school_id = null" do
      post "/students", params: base_body.merge(school_id: nil), as: :json
      expect(response).to have_http_status(405)
    end
  end

  describe "массовое создание (целостность counter_cache)" do
    it "students_count корректен после 20 INSERT'ов подряд" do
      20.times do |i|
        post "/students",
             params: base_body.merge(first_name: "Студент#{i}"),
             as: :json
        expect(response).to have_http_status(:created)
      end
      expect(klass.reload.students_count).to eq(20)
    end
  end

  describe "пустая строка vs nil" do
    it "пустая строка для first_name → 405 (presence-валидация)" do
      post "/students", params: base_body.merge(first_name: ""), as: :json
      expect(response).to have_http_status(405)
    end
  end

  describe "неизвестные поля в body" do
    it "игнорирует unknown_field и создаёт студента (strong params)" do
      post "/students",
           params: base_body.merge(admin: true, unknown_field: "ignored"),
           as: :json
      expect(response).to have_http_status(:created)
      expect(json_body.keys).not_to include("admin", "unknown_field")
    end
  end
end
