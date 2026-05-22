# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_05_22_120002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "classes", force: :cascade do |t|
    t.integer "number", null: false
    t.string "letter", null: false
    t.bigint "school_id", null: false
    t.integer "students_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "number", "letter"], name: "index_classes_on_school_id_and_number_and_letter", unique: true
    t.index ["school_id"], name: "index_classes_on_school_id"
  end

  create_table "schools", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "students", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "surname", null: false
    t.bigint "school_id", null: false
    t.bigint "class_id", null: false
    t.string "auth_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auth_token"], name: "index_students_on_auth_token", unique: true
    t.index ["class_id"], name: "index_students_on_class_id"
    t.index ["school_id"], name: "index_students_on_school_id"
  end

  add_foreign_key "classes", "schools"
  add_foreign_key "students", "classes"
  add_foreign_key "students", "schools"
end
