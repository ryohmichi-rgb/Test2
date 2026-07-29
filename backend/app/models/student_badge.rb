# 獲得したバッジの記録。定義そのものは BadgeCatalog（コード側）にある。
# 獲得日時を残すのは「取った瞬間のお祝い」を出すため（都度計算だと変化を検知できない）。
class StudentBadge < ApplicationRecord
  belongs_to :student

  validates :badge_key, presence: true, uniqueness: { scope: :student_id }
end
