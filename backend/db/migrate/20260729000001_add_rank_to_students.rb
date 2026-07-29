class AddRankToStudents < ActiveRecord::Migration[8.0]
  def change
    # rank_id が NULL の生徒は「最下位ランク」とみなす（Student#current_rank）。
    # そうすることで既存生徒のバックフィルが要らない。
    add_reference :students, :rank, null: true, foreign_key: true

    # 昇格試験に落ちた時点の合計ポイント。ここから RETRY_POINTS 伸ばすと再挑戦できる。
    # 合格するか、まだ一度も落ちていなければ NULL。
    add_column :students, :last_exam_points, :integer

    # 選択中の称号（= その称号を持つバッジの key）。未選択なら NULL。
    add_column :students, :title_key, :string
  end
end
