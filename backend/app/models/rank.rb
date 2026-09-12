# ランクの段位（10級 → 1級 → 初段）。**「教科のまとまり」ごと**に、そのまとまりで
# 積んだポイントで到達を判定する（RankPoints）。到達しただけでは上がらず、
# 昇格試験に合格して初めて昇格する（PromotionExam）。
class Rank < ApplicationRecord
  has_many :student_ranks, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :threshold_points, :display_order, presence: true
  validates :threshold_points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :display_order, numericality: { only_integer: true, greater_than: 0 }, uniqueness: true
  validates :exam_question_count, numericality: { only_integer: true, greater_than: 0 }
  validates :pass_percent, numericality: { only_integer: true, in: 1..100 }
  validate :threshold_must_increase_with_order

  scope :ordered, -> { order(:display_order) }

  # 管理画面から消してよいか。そのランクの生徒がいたら消させない。
  # 消すと student_ranks.rank_id が NULL になり最下位ランク扱い＝実質の降格になるため
  # （「降格はしない」という約束を守る）。
  def used?
    student_ranks.exists?
  end

  def self.lowest
    ordered.first
  end

  # 合計ポイントから「到達しているはずの最高ランク」を返す（昇格試験は考慮しない）
  def self.reached_by(points)
    ordered.where(threshold_points: ..points.to_i).last || lowest
  end

  def next_rank
    self.class.ordered.where(display_order: (display_order + 1)..).first
  end

  def top?
    next_rank.nil?
  end

  private

  # しきい値は段位の順に増えていなければならない。
  # `reached_by` が「しきい値が points 以下のうち display_order が最後のもの」を返す作りなので、
  # 順番が逆転すると到達判定がおかしくなる（下の級に届く前に上の級に到達してしまう）。
  def threshold_must_increase_with_order
    return if threshold_points.blank? || display_order.blank?

    others = self.class.where.not(id: id)
    below = others.where(display_order: ...display_order).maximum(:threshold_points)
    above = others.where(display_order: (display_order + 1)..).minimum(:threshold_points)

    if below && threshold_points < below
      errors.add(:threshold_points, "は下の段位（#{below}pt）以上にしてください")
    end
    if above && threshold_points > above
      errors.add(:threshold_points, "は上の段位（#{above}pt）以下にしてください")
    end
  end
end
