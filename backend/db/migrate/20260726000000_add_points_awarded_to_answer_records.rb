class AddPointsAwardedToAnswerRecords < ActiveRecord::Migration[8.1]
  # 回答1件ごとに「そのとき確定したポイント」を保存する。
  #
  # farming対策で「同じ問題の解き直しは満点の20%」「前回正解から14日で満点に復帰」という
  # 時系列に依存するルールを入れるため、あとから再計算すると過去の値まで変わってしまう。
  # 回答時に確定させてレコードに持たせることで、成長曲線・今日のノルマは単純なSUMで済み、
  # 加点ロジックが1箇所（AnswerRecord）に集約される。
  def up
    add_column :answer_records, :points_awarded, :integer, null: false, default: 0

    # 既存レコードは「満点」で埋める（実ユーザーがまだいないため過去は不問とする）。
    # 不正解は 0 のまま。難易度4・5はこれまで10ptにフォールバックしていたが、
    # ここでは新しい配点（25/30）で埋め直す。
    execute <<~SQL
      UPDATE answer_records AS ar
      SET points_awarded = CASE p.difficulty
                             WHEN 1 THEN 10
                             WHEN 2 THEN 15
                             WHEN 3 THEN 20
                             WHEN 4 THEN 25
                             WHEN 5 THEN 30
                             ELSE 10
                           END
      FROM problems AS p
      WHERE p.id = ar.problem_id
        AND ar.is_correct = TRUE
    SQL

    # 「この生徒がこの問題を前回いつ正解したか」を引くための索引。
    # 加点の逓減判定と、出題の重複回避の両方で使う。
    add_index :answer_records, [:student_id, :problem_id, :created_at],
              name: "index_answer_records_on_student_problem_time"
  end

  def down
    remove_index :answer_records, name: "index_answer_records_on_student_problem_time"
    remove_column :answer_records, :points_awarded
  end
end
