require "rails_helper"

RSpec.describe School do
  it "не валидна без имени" do
    expect(School.new).not_to be_valid
  end

  it "валидна с именем" do
    expect(School.new(name: "Школа")).to be_valid
  end

  it "удаляет связанные классы при destroy" do
    school = School.create!(name: "Школа")
    school.school_classes.create!(number: 1, letter: "А")
    expect { school.destroy }.to change(SchoolClass, :count).by(-1)
  end
end
