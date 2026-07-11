class TestResult < ApplicationRecord
  belongs_to :student

  SCOPE_TYPES = %w[grade stat_type unit].freeze

  validates :scope_type, inclusion: { in: SCOPE_TYPES }
  validates :total_questions, :correct_count, :score_percent, presence: true

  scope :recent_first, -> { order(created_at: :desc) }

  # 同じ範囲での直前の結果（前回比較用）。self より前のものを返す。
  def previous
    TestResult
      .where(student_id: student_id, scope_type: scope_type, scope_id: scope_id)
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
