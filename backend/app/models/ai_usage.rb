class AiUsage < ApplicationRecord
  belongs_to :student
  belongs_to :problem, optional: true

  # 「先生に聞く」の質問の種類（character_key が nil のとき）
  TEACHER_KINDS = %w[hint approach why free].freeze
  # 「この人に聞く」の質問の種類（character_key があるとき）
  PERSONA_KINDS = PersonaCatalog::KINDS.keys.freeze

  KINDS = (TEACHER_KINDS | PERSONA_KINDS).freeze
  validates :kind, inclusion: { in: KINDS }

  # 今日（アプリのタイムゾーン基準）の分だけ
  scope :today, -> { where(created_at: Time.zone.now.beginning_of_day..) }
  # 先生とペルソナは回数の枠を分ける。片方の使いすぎでもう片方が使えなくなると困るため。
  scope :teacher, -> { where(character_key: nil) }
  scope :persona, -> { where.not(character_key: nil) }
end
