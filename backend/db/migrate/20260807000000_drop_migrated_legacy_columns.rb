# 移行ずみの旧列を落とす。
#
#   units.stat_type_id          → unit_stat_types（1単元に複数のステータス）
#   students.rank_id            → student_ranks.rank_id（教科のまとまりごとのランク）
#   students.last_exam_points   → student_ranks.last_exam_points
#
# どれも移行と同じリリースでは消さなかった。デプロイ中は旧コードが新スキーマに対して
# 動く窓があり、`units.*` や `students.*` を読む旧インスタンスがその間だけ落ちるため。
# 参照を外したリリースはすでに出ているので、ここで消す。
class DropMigratedLegacyColumns < ActiveRecord::Migration[8.0]
  def up
    remove_foreign_key :units, :stat_types
    remove_column :units, :stat_type_id

    remove_foreign_key :students, :ranks
    remove_column :students, :rank_id
    remove_column :students, :last_exam_points
  end

  # 戻すときは列を作り直して、いまのデータから埋める。
  # units は1単元1ステータスしか持てないので、表示順の先頭を入れる（複数付いていれば落ちる）。
  def down
    add_reference :units, :stat_type, null: true, foreign_key: true
    execute <<~SQL
      UPDATE units SET stat_type_id = (
        SELECT ust.stat_type_id FROM unit_stat_types ust
        JOIN stat_types st ON st.id = ust.stat_type_id
        WHERE ust.unit_id = units.id
        ORDER BY st.display_order, st.id LIMIT 1
      )
    SQL

    add_reference :students, :rank, null: true, foreign_key: true
    add_column :students, :last_exam_points, :integer
    execute <<~SQL
      UPDATE students SET
        rank_id = (SELECT sr.rank_id FROM student_ranks sr WHERE sr.student_id = students.id ORDER BY sr.id LIMIT 1),
        last_exam_points = (SELECT sr.last_exam_points FROM student_ranks sr WHERE sr.student_id = students.id ORDER BY sr.id LIMIT 1)
    SQL
  end
end
