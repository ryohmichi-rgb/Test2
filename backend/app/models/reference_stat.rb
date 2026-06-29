class ReferenceStat < ApplicationRecord
  belongs_to :stat_type

  validates :label, presence: true
  validates :value, numericality: { greater_than: 0 }
end
