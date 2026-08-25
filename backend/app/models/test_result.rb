class TestResult < ApplicationRecord
  belongs_to :student
  # 教科は範囲（scope_type/scope_id）とは別軸のしぼり込み。教科が1つしか無いうちは nil。
  belongs_to :subject, optional: true

  # ユーザーがテストの範囲として選べるもの
  SCOPE_TYPES = %w[grade stat_type unit].freeze
  # 記録として保存されうるもの。昇格試験は範囲として選ばせないが結果は履歴に残す。
  RECORDED_SCOPE_TYPES = (SCOPE_TYPES + %w[promotion]).freeze

  validates :scope_type, inclusion: { in: RECORDED_SCOPE_TYPES }

  def promotion?
    scope_type == "promotion"
  end
  validates :total_questions, :correct_count, :score_percent, presence: true

  scope :recent_first, -> { order(created_at: :desc) }

  # 同じ範囲での直前の結果（前回比較用）。self より前のものを返す。
  # 教科もそろえないと「小6の算数」と「小6の国語」が同じ範囲として比べられてしまう。
  def previous
    TestResult
      .where(student_id: student_id, scope_type: scope_type, scope_id: scope_id, subject_id: subject_id)
      .where("created_at < ?", created_at)
      .order(created_at: :desc)
      .first
  end

  def rank
    case score_percent
    when 90..100 then "S"
    when 80...90 then "A"
    when 60...80 then "B"
    else "C"
    end
  end
end
