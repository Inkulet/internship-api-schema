require "rails_helper"

RSpec.describe SchoolClass do
  let(:school) { School.create!(name: "Школа") }

  it "имеет таблицу 'classes'" do
    expect(SchoolClass.table_name).to eq("classes")
  end

  it "не валидна без школы" do
    expect(SchoolClass.new(number: 1, letter: "А")).not_to be_valid
  end

  it "не валидна с number <= 0" do
    expect(SchoolClass.new(school: school, number: 0, letter: "А")).not_to be_valid
  end

  it "не валидна без letter" do
    expect(SchoolClass.new(school: school, number: 1)).not_to be_valid
  end

  it "не допускает дубликат (school, number, letter)" do
    school.school_classes.create!(number: 1, letter: "А")
    expect(SchoolClass.new(school: school, number: 1, letter: "А")).not_to be_valid
  end

  it "to_api_hash возвращает только {id, number, letter, students_count}" do
    klass = school.school_classes.create!(number: 1, letter: "А")
    expect(klass.to_api_hash.keys).to match_array(%i[id number letter students_count])
  end
end
