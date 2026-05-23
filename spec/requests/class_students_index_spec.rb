require "rails_helper"

RSpec.describe "GET /schools/:school_id/classes/:class_id/students", type: :request do
  let(:school) { School.create!(name: "Школа") }
  let(:klass)  { school.school_classes.create!(number: 1, letter: "А") }

  before do
    @ivan  = Student.create!(school: school, school_class: klass,
                             first_name: "Иван",  last_name: "Иванов",  surname: "Иванович")
    @anna  = Student.create!(school: school, school_class: klass,
                             first_name: "Анна",  last_name: "Алексеева", surname: "Игоревна")
    @petr  = Student.create!(school: school, school_class: klass,
                             first_name: "Пётр",  last_name: "Петров",   surname: "Петрович")
  end

  it "возвращает 200" do
    get "/schools/#{school.id}/classes/#{klass.id}/students"
    expect(response).to have_http_status(:ok)
  end

  it "обёртывает в data" do
    get "/schools/#{school.id}/classes/#{klass.id}/students"
    expect(json_body["data"]).to be_an(Array)
    expect(json_body["data"].size).to eq(3)
  end

  it "сортирует по фамилии" do
    get "/schools/#{school.id}/classes/#{klass.id}/students"
    last_names = json_body["data"].map { |s| s["last_name"] }
    expect(last_names).to eq([ "Алексеева", "Иванов", "Петров" ])
  end

  it "у каждого студента ровно 6 публичных полей" do
    get "/schools/#{school.id}/classes/#{klass.id}/students"
    expect(json_body["data"].first.keys)
      .to match_array(%w[id first_name last_name surname class_id school_id])
  end

  it "не отдаёт auth_token" do
    get "/schools/#{school.id}/classes/#{klass.id}/students"
    expect(json_body["data"].first.keys).not_to include("auth_token")
  end

  it "не возвращает учеников чужого класса" do
    other_class = school.school_classes.create!(number: 9, letter: "Б")
    Student.create!(school: school, school_class: other_class,
                    first_name: "Чужой", last_name: "Студент", surname: "Х")
    get "/schools/#{school.id}/classes/#{klass.id}/students"
    expect(json_body["data"].map { |s| s["first_name"] }).not_to include("Чужой")
  end

  it "возвращает пустой data на несуществующий класс" do
    get "/schools/#{school.id}/classes/999999/students"
    expect(json_body["data"]).to eq([])
  end

  context "пагинация" do
    it "?per_page=2 возвращает 2 учеников" do
      get "/schools/#{school.id}/classes/#{klass.id}/students", params: { per_page: 2 }
      expect(json_body["data"].size).to eq(2)
    end
  end
end
