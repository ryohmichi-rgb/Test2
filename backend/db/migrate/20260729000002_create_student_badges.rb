class CreateStudentBadges < ActiveRecord::Migration[8.0]
  def change
    # バッジの「定義」はコード側（BadgeCatalog）に置く。条件が「連続日数」「単元制覇」
    # 「直近20問の正答率」など列で表せないため。ここに残すのは獲得した事実だけ。
    create_table :student_badges do |t|
      t.references :student, null: false, foreign_key: true
      t.string :badge_key, null: false
      t.datetime :earned_at, null: false

      t.timestamps
    end

    add_index :student_badges, [:student_id, :badge_key], unique: true
  end
end
