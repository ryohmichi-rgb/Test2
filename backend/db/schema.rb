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

ActiveRecord::Schema[8.1].define(version: 2026_06_27_135334) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "answer_records", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_correct"
    t.bigint "problem_id", null: false
    t.bigint "student_id", null: false
    t.string "submitted_answer"
    t.datetime "updated_at", null: false
    t.index ["problem_id"], name: "index_answer_records_on_problem_id"
    t.index ["student_id"], name: "index_answer_records_on_student_id"
  end

  create_table "choices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_correct"
    t.bigint "problem_id", null: false
    t.string "text"
    t.datetime "updated_at", null: false
    t.index ["problem_id"], name: "index_choices_on_problem_id"
  end

  create_table "grades", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "display_order"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "problems", force: :cascade do |t|
    t.string "answer"
    t.datetime "created_at", null: false
    t.integer "difficulty"
    t.text "hint"
    t.string "problem_type"
    t.text "question"
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["unit_id"], name: "index_problems_on_unit_id"
  end

  create_table "students", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "subjects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "units", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "display_order"
    t.bigint "grade_id", null: false
    t.bigint "subject_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["grade_id"], name: "index_units_on_grade_id"
    t.index ["subject_id"], name: "index_units_on_subject_id"
  end

  add_foreign_key "answer_records", "problems"
  add_foreign_key "answer_records", "students"
  add_foreign_key "choices", "problems"
  add_foreign_key "problems", "units"
  add_foreign_key "units", "grades"
  add_foreign_key "units", "subjects"
end
