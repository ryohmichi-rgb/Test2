# ランクを「教科のまとまり」ごとに持つ。
#
# 教科そのものを単位にしないのは、算数（小6）と数学（中1）が**学年と1対1**で、
# 実質ひとつながりの積み上げだから。教科で割ると中1に進んだ時点で算数のランクが止まり、
# 数学は10級からやり直しになってしまう。
#
# students.rank_id / last_exam_points はこの移行では消さない（デプロイ中に旧コードが
# 新スキーマに対して動く窓があるため）。参照はすべて student_ranks に移す。
class CreateSubjectGroupsAndStudentRanks < ActiveRecord::Migration[8.0]
  def up
    create_table :subject_groups do |t|
      t.string :name, null: false
      t.integer :display_order, null: false, default: 0
      t.timestamps
    end

    add_reference :subjects, :subject_group, null: true, foreign_key: true

    create_table :student_ranks do |t|
      t.references :student, null: false, foreign_key: true
      t.references :subject_group, null: false, foreign_key: true
      t.references :rank, null: true, foreign_key: true
      # 昇格試験に落ちたときの再挑戦しきい値（そのまとまりのポイント）
      t.integer :last_exam_points
      t.timestamps
    end
    add_index :student_ranks, [:student_id, :subject_group_id], unique: true

    # 既存の教科はすべて「算数・数学」ひとまとまりにする。
    # ここで分けると、いまの子のランクをどちらに渡すか決められない。
    if execute("SELECT COUNT(*) FROM subjects").first["count"].to_i > 0
      execute <<~SQL
        INSERT INTO subject_groups (name, display_order, created_at, updated_at)
        VALUES ('算数・数学', 0, NOW(), NOW())
      SQL
      execute <<~SQL
        UPDATE subjects SET subject_group_id = (SELECT id FROM subject_groups ORDER BY id LIMIT 1)
      SQL

      # いまのランクと再挑戦しきい値をそのまとまりへ引き継ぐ（下がったように見せない）
      execute <<~SQL
        INSERT INTO student_ranks (student_id, subject_group_id, rank_id, last_exam_points, created_at, updated_at)
        SELECT s.id, (SELECT id FROM subject_groups ORDER BY id LIMIT 1), s.rank_id, s.last_exam_points, NOW(), NOW()
        FROM students s
        WHERE s.rank_id IS NOT NULL OR s.last_exam_points IS NOT NULL
      SQL
    end
  end

  def down
    drop_table :student_ranks
    remove_reference :subjects, :subject_group, foreign_key: true
    drop_table :subject_groups
  end
end
