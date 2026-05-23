require "rails_helper"

RSpec.describe "POST /students", type: :request do
  let(:school) { School.create!(name: "Школа") }
  let(:klass)  { school.school_classes.create!(number: 1, letter: "А") }

  let(:valid_body) do
    {
      first_name: "Иван",
      last_name:  "Иванов",
      surname:    "Иванович",
      class_id:   klass.id,
      school_id:  school.id
    }
  end

  context "с валидным телом" do
    before { post "/students", params: valid_body, as: :json }

    it "возвращает 201" do
      expect(response).to have_http_status(:created)
    end

    it "возвращает Student-схему ровно из 6 полей без auth_token" do
      expect(json_body.keys).to match_array(%w[id first_name last_name surname class_id school_id])
    end

    it "выставляет заголовок X-Auth-Token из 64 hex-символов" do
      expect(response.headers["X-Auth-Token"]).to match(/\A[a-f0-9]{64}\z/)
    end

    it "создаёт запись в БД" do
      expect(Student.find(json_body["id"])).to be_present
    end

    it "инкрементит students_count у класса" do
      expect(klass.reload.students_count).to eq(1)
    end
  end

  context "ошибки" do
    it "405 на пустое тело" do
      post "/students", params: {}, as: :json
      expect(response).to have_http_status(405)
      expect(json_body).to include("error" => "Invalid input")
    end

    it "405 на отсутствующие поля" do
      post "/students", params: { first_name: "X" }, as: :json
      expect(response).to have_http_status(405)
    end

    it "405 на несуществующий class_id" do
      post "/students", params: valid_body.merge(class_id: 999_999), as: :json
      expect(response).to have_http_status(405)
    end

    it "405 на класс из другой школы" do
      other = School.create!(name: "Другая").school_classes.create!(number: 5, letter: "Б")
      post "/students", params: valid_body.merge(class_id: other.id), as: :json
      expect(response).to have_http_status(405)
    end

    it "405 на битый JSON" do
      post "/students",
           params: "{not json",
           headers: { "CONTENT_TYPE" => "application/json" }
      expect(response).to have_http_status(405)
    end
  end
end
