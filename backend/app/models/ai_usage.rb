class AiUsage < ApplicationRecord
  belongs_to :student
  belongs_to :problem, optional: true

  KINDS = %w[hint approach why free].freeze
  validates :kind, inclusion: { in: KINDS }

  # 今日（アプリのタイムゾーン基準）の分だけ
  scope :today, -> { where(created_at: Time.zone.now.beginning_of_day..) }
end
