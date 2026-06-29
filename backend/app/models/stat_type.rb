class StatType < ApplicationRecord
  has_many :student_stats
  has_many :goals
  has_many :reference_stats
  has_many :units

  validates :name, presence: true, uniqueness: true
  default_scope { order(:display_order) }
end
