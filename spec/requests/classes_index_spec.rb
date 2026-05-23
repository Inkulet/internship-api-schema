require "rails_helper"

RSpec.describe "GET /schools/:school_id/classes", type: :request do
  let(:school) { School.create!(name: "Школа") }

  before do
    @class_1a = school.school_classes.create!(number: 1, letter: "А")
    @class_1b = school.school_classes.create!(number: 1, letter: "Б")
    @class_5a = school.school_classes.create!(number: 5, letter: "А")
    Student.create!(school: school, school_class: @class_1a,
                    first_name: "Иван", last_name: "Иванов", surname: "Иванович")
  end

  it "возвращает 200" do
    get "/schools/#{school.id}/classes"
    expect(response).to have_http_status(:ok)
  end

  it "обёртывает результат в data" do
    get "/schools/#{school.id}/classes"
    expect(json_body).to have_key("data")
    expect(json_body["data"]).to be_an(Array)
  end

  it "возвращает классы школы, отсортированные по (number, letter)" do
    get "/schools/#{school.id}/classes"
    pairs = json_body["data"].map { |c| [ c["number"], c["letter"] ] }
    expect(pairs).to eq([ [ 1, "А" ], [ 1, "Б" ], [ 5, "А" ] ])
  end

  it "у каждого класса ровно поля {id, number, letter, students_count}" do
    get "/schools/#{school.id}/classes"
    expect(json_body["data"].first.keys).to match_array(%w[id number letter students_count])
  end

  it "students_count соответствует количеству учеников" do
    get "/schools/#{school.id}/classes"
    found = json_body["data"].find { |c| c["letter"] == "А" && c["number"] == 1 }
    expect(found["students_count"]).to eq(1)
  end

  it "не возвращает классы чужих школ" do
    other = School.create!(name: "Другая")
    other.school_classes.create!(number: 9, letter: "Я")
    get "/schools/#{school.id}/classes"
    letters = json_body["data"].map { |c| c["letter"] }
    expect(letters).not_to include("Я")
  end

  it "возвращает пустой data на несуществующую школу" do
    get "/schools/999999/classes"
    expect(json_body["data"]).to eq([])
  end

  context "пагинация" do
    it "без параметров возвращает все классы" do
      get "/schools/#{school.id}/classes"
      expect(json_body["data"].size).to eq(3)
    end

    it "?per_page=2 возвращает 2 класса" do
      get "/schools/#{school.id}/classes", params: { per_page: 2 }
      expect(json_body["data"].size).to eq(2)
    end

    it "?page=2&per_page=2 возвращает оставшийся класс" do
      get "/schools/#{school.id}/classes", params: { page: 2, per_page: 2 }
      expect(json_body["data"].size).to eq(1)
    end
  end
end
