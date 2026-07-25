class LessonRead < ApplicationRecord
  belongs_to :student
  belongs_to :unit

  validates :student_id, uniqueness: { scope: :unit_id }

  # 教材の初回読了で入るポイント。成長曲線でも同じ値を使うのでモデル側に置く。
  POINTS = 5
end
