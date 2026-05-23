require "rails_helper"

RSpec.describe "DELETE /students/:user_id", type: :request do
  let(:school)  { School.create!(name: "Школа") }
  let(:klass)   { school.school_classes.create!(number: 1, letter: "А") }
  let(:student) do
    Student.create!(school: school, school_class: klass,
                    first_name: "Иван", last_name: "Иванов", surname: "Иванович")
  end
  let(:token) { student.reload.auth_token }

  context "с корректным Bearer-токеном" do
    it "возвращает 204" do
      delete "/students/#{student.id}", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:no_content)
    end

    it "удаляет запись" do
      delete "/students/#{student.id}", headers: { "Authorization" => "Bearer #{token}" }
      expect(Student.exists?(student.id)).to be(false)
    end

    it "декрементит students_count" do
      student # create
      expect {
        delete "/students/#{student.id}", headers: { "Authorization" => "Bearer #{token}" }
      }.to change { klass.reload.students_count }.by(-1)
    end

    it "принимает Bearer в любом регистре" do
      delete "/students/#{student.id}", headers: { "Authorization" => "bearer #{token}" }
      expect(response).to have_http_status(:no_content)
    end
  end

  context "401 — авторизация" do
    it "без заголовка" do
      delete "/students/#{student.id}"
      expect(response).to have_http_status(:unauthorized)
    end

    it "с неправильным токеном" do
      delete "/students/#{student.id}",
             headers: { "Authorization" => "Bearer wrong-token-value" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "с пустым Bearer" do
      delete "/students/#{student.id}", headers: { "Authorization" => "Bearer " }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "400 — некорректный id" do
    it "нечисловой id" do
      delete "/students/abc", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:bad_request)
    end

    it "несуществующий id" do
      delete "/students/999999", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:bad_request)
    end

    it "уже удалённый id" do
      delete "/students/#{student.id}", headers: { "Authorization" => "Bearer #{token}" }
      delete "/students/#{student.id}", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:bad_request)
    end
  end
end
