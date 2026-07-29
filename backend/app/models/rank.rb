# 総合ランク（10級 → 1級 → 初段）。全ステータスの合計ポイントで到達を判定する。
# 到達しただけでは上がらず、昇格試験に合格して初めて昇格する（PromotionExam）。
class Rank < ApplicationRecord
  has_many :students, dependent: :nullify

  validates :name, presence: true
  validates :threshold_points, :display_order, presence: true

  scope :ordered, -> { order(:display_order) }

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
end
