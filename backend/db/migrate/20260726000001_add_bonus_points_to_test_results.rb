class AddBonusPointsToTestResults < ActiveRecord::Migration[8.1]
  # テストの高得点ボーナス（自己ベスト更新時のみ・最大100pt）を記録する。
  #
  # これまでボーナスは student_stats に直接足すだけで金額をどこにも残していなかったため、
  # answer_records から再構築する成長曲線にボーナス分が現れず、
  # 折れ線の最後（現在値＝student_stats）だけが跳ね上がる状態になっていた。
  #
  # 過去のボーナス額は復元できないので既存行は 0 のまま。今後の分から正しく記録される。
  def change
    add_column :test_results, :bonus_points, :integer, null: false, default: 0
  end
end
