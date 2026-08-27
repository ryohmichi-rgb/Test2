class Unit < ApplicationRecord
  belongs_to :grade
  belongs_to :subject
  # 単元が伸ばすステータス（複数可）。読み書きはすべてこちらを使う。
  has_many :unit_stat_types, dependent: :destroy
  has_many :stat_types, -> { order(:display_order, :id) }, through: :unit_stat_types
  has_many :problems, dependent: :destroy

  validates :title, presence: true
  validates :display_order, presence: true

  scope :ordered, -> { order(:display_order) }
  scope :active_only, -> { where(active: true) }
  # そのステータスを伸ばす単元（複数持つ単元も、どれか1つ一致すれば入る）
  scope :for_stat_type, ->(stat_type_id) {
    where(id: UnitStatType.where(stat_type_id: stat_type_id).select(:unit_id))
  }
end
