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

ActiveRecord::Schema[8.1].define(version: 2026_08_05_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ai_usages", force: :cascade do |t|
    t.string "character_key"
    t.datetime "created_at", null: false
    t.string "kind", default: "hint", null: false
    t.bigint "problem_id"
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["problem_id"], name: "index_ai_usages_on_problem_id"
    t.index ["student_id", "character_key", "created_at"], name: "index_ai_usages_on_student_character_created"
    t.index ["student_id", "created_at"], name: "index_ai_usages_on_student_id_and_created_at"
    t.index ["student_id"], name: "index_ai_usages_on_student_id"
  end

  create_table "answer_records", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_correct"
    t.integer "points_awarded", default: 0, null: false
    t.bigint "problem_id", null: false
    t.bigint "student_id", null: false
    t.string "submitted_answer"
    t.datetime "updated_at", null: false
    t.index ["problem_id"], name: "index_answer_records_on_problem_id"
    t.index ["student_id", "problem_id", "created_at"], name: "index_answer_records_on_student_problem_time"
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

  create_table "daily_quotas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "on_date", null: false
    t.bigint "student_id", null: false
    t.integer "target_points", null: false
    t.datetime "updated_at", null: false
    t.index ["student_id", "on_date"], name: "index_daily_quotas_on_student_id_and_on_date", unique: true
    t.index ["student_id"], name: "index_daily_quotas_on_student_id"
  end

  create_table "goals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "stat_type_id", null: false
    t.bigint "student_id", null: false
    t.date "target_date"
    t.integer "target_value"
    t.datetime "updated_at", null: false
    t.index ["stat_type_id"], name: "index_goals_on_stat_type_id"
    t.index ["student_id"], name: "index_goals_on_student_id"
  end

  create_table "grades", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "display_order"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "guardianships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "guardian_id", null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["guardian_id", "student_id"], name: "index_guardianships_on_guardian_id_and_student_id", unique: true
    t.index ["guardian_id"], name: "index_guardianships_on_guardian_id"
    t.index ["student_id"], name: "index_guardianships_on_student_id"
  end

  create_table "lesson_reads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "student_id", null: false
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["student_id", "unit_id"], name: "index_lesson_reads_on_student_id_and_unit_id", unique: true
    t.index ["student_id"], name: "index_lesson_reads_on_student_id"
    t.index ["unit_id"], name: "index_lesson_reads_on_unit_id"
  end

  create_table "problems", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "answer"
    t.datetime "created_at", null: false
    t.integer "difficulty"
    t.text "hint"
    t.string "problem_type"
    t.text "question"
    t.text "solution"
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["unit_id"], name: "index_problems_on_unit_id"
  end

  create_table "ranks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "display_order", null: false
    t.integer "exam_question_count", default: 10, null: false
    t.string "name", null: false
    t.integer "pass_percent", default: 80, null: false
    t.integer "threshold_points", null: false
    t.datetime "updated_at", null: false
    t.index ["display_order"], name: "index_ranks_on_display_order", unique: true
  end

  create_table "reference_stats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label"
    t.bigint "stat_type_id", null: false
    t.datetime "updated_at", null: false
    t.integer "value"
    t.index ["stat_type_id"], name: "index_reference_stats_on_stat_type_id"
  end

  create_table "stat_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "display_order"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "student_badges", force: :cascade do |t|
    t.string "badge_key", null: false
    t.datetime "created_at", null: false
    t.datetime "earned_at", null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.index ["student_id", "badge_key"], name: "index_student_badges_on_student_id_and_badge_key", unique: true
    t.index ["student_id"], name: "index_student_badges_on_student_id"
  end

  create_table "student_stats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "stat_type_id", null: false
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.integer "value"
    t.index ["stat_type_id"], name: "index_student_stats_on_stat_type_id"
    t.index ["student_id"], name: "index_student_stats_on_student_id"
  end

  create_table "students", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "last_exam_points"
    t.string "name"
    t.boolean "onboarded", default: false, null: false
    t.string "password_digest"
    t.bigint "rank_id"
    t.string "role", default: "student", null: false
    t.string "title_key"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["rank_id"], name: "index_students_on_rank_id"
    t.index ["role"], name: "index_students_on_role"
    t.index ["username"], name: "index_students_on_username", unique: true
  end

  create_table "subjects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "test_results", force: :cascade do |t|
    t.integer "bonus_points", default: 0, null: false
    t.integer "correct_count"
    t.datetime "created_at", null: false
    t.integer "scope_id"
    t.string "scope_label"
    t.string "scope_type"
    t.integer "score_percent"
    t.bigint "student_id", null: false
    t.bigint "subject_id"
    t.integer "total_questions"
    t.datetime "updated_at", null: false
    t.index ["student_id", "scope_type", "created_at"], name: "index_test_results_on_student_id_and_scope_type_and_created_at"
    t.index ["student_id"], name: "index_test_results_on_student_id"
    t.index ["subject_id"], name: "index_test_results_on_subject_id"
  end

  create_table "unit_stat_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "stat_type_id", null: false
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stat_type_id"], name: "index_unit_stat_types_on_stat_type_id"
    t.index ["unit_id", "stat_type_id"], name: "index_unit_stat_types_on_unit_id_and_stat_type_id", unique: true
    t.index ["unit_id"], name: "index_unit_stat_types_on_unit_id"
  end

  create_table "units", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "display_order"
    t.bigint "grade_id", null: false
    t.text "lesson_body"
    t.bigint "stat_type_id"
    t.bigint "subject_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["grade_id"], name: "index_units_on_grade_id"
    t.index ["stat_type_id"], name: "index_units_on_stat_type_id"
    t.index ["subject_id"], name: "index_units_on_subject_id"
  end

  add_foreign_key "ai_usages", "problems"
  add_foreign_key "ai_usages", "students"
  add_foreign_key "answer_records", "problems"
  add_foreign_key "answer_records", "students"
  add_foreign_key "choices", "problems"
  add_foreign_key "daily_quotas", "students"
  add_foreign_key "goals", "stat_types"
  add_foreign_key "goals", "students"
  add_foreign_key "guardianships", "students"
  add_foreign_key "guardianships", "students", column: "guardian_id"
  add_foreign_key "lesson_reads", "students"
  add_foreign_key "lesson_reads", "units"
  add_foreign_key "problems", "units"
  add_foreign_key "reference_stats", "stat_types"
  add_foreign_key "student_badges", "students"
  add_foreign_key "student_stats", "stat_types"
  add_foreign_key "student_stats", "students"
  add_foreign_key "students", "ranks"
  add_foreign_key "test_results", "students"
  add_foreign_key "test_results", "subjects"
  add_foreign_key "unit_stat_types", "stat_types"
  add_foreign_key "unit_stat_types", "units"
  add_foreign_key "units", "grades"
  add_foreign_key "units", "stat_types"
  add_foreign_key "units", "subjects"
end
