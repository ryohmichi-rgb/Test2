# テストの範囲に「教科」の軸を足す。
# 範囲（学年 / ステータス / 単元）とは別軸のしぼり込みなので、scope_type ではなく列で持つ。
# 自己ベストの比較が scope_type + scope_id で行われるため、ここを分けておかないと
# 「小6の算数」と「小6の国語」の点数が同じ範囲として比べられてしまう。
class AddSubjectToTestResults < ActiveRecord::Migration[8.0]
  def change
    add_reference :test_results, :subject, null: true, foreign_key: true
  end
end
