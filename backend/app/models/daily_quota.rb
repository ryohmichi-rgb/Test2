# その日のノルマ（目標ポイント）の記録。
#
# ノルマは goals と当時のステータス値から計算するが、goals は上書き更新で履歴を持たない。
# つまり **過去のある日のノルマは、あとから復元できない**。「ノルマを達成した日」の連続を
# 数えるには、その日のうちに決めて残しておくしかない。
# （稼いだポイントは answer_records.points_awarded が確定値なので、ここには持たず毎回集計する）
#
# ノルマは**その日はじめて計算したときに決めて、以後その日は変えない**。
# 日中に目標が動くと「達成したのに達成していないことになる」ため。
# 加点を回答時に確定させているのと同じ考え方。
class DailyQuota < ApplicationRecord
  # Rails は "quota" をラテン語由来の複数形と見なすので（"quota".pluralize == "quota"）、
  # 放っておくとテーブル名が daily_quota になる。ほかのテーブルと形をそろえるため明示する。
  self.table_name = "daily_quotas"

  belongs_to :student

  DEFAULT_TARGET = 30            # 目標未設定時のゆるいノルマ
  EST_POINTS_PER_PROBLEM = 15    # 目安の問題数を出すための概算

  validates :on_date, presence: true, uniqueness: { scope: :student_id }
  validates :target_points, presence: true

  # その日のノルマを取り出す（なければ決めて記録する）。
  def self.for(student, date = Date.current)
    find_by(student_id: student.id, on_date: date) ||
      create!(student: student, on_date: date, target_points: calculate_target(student, date))
  rescue ActiveRecord::RecordNotUnique
    # ほぼ同時に2つのリクエストが来たとき。先に入った方を使う。
    find_by!(student_id: student.id, on_date: date)
  end

  # 目標ペースから1日あたり必要ポイントを出し、「いま満点で解ける量」で上限を切る。
  # 達成できないノルマを出し続けないため。全部解ききっていれば 0 になる。
  def self.calculate_target(student, date = Date.current)
    goals = student.goals.includes(:stat_type)
    current = StudentStat.where(student: student).pluck(:stat_type_id, :value).to_h

    target =
      if goals.any?
        goals.sum do |g|
          needed = [g.target_value - (current[g.stat_type_id] || 0), 0].max
          days = [(g.target_date - date).to_i, 1].max
          (needed.to_f / days).ceil
        end
      else
        DEFAULT_TARGET
      end

    [target, full_point_capacity(student)].min
  end

  # 未挑戦・要復習・回復済みの問題を満点換算した合計
  def self.full_point_capacity(student)
    ProblemScope.all_problems
      .full_point_problems_for(student)
      .sum { |p| AnswerRecord.full_points_for(p.difficulty) }
  end

  def approx_problems
    return 0 if target_points <= 0
    [(target_points.to_f / EST_POINTS_PER_PROBLEM).ceil, 1].max
  end
end
