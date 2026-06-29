class Goal < ApplicationRecord
  belongs_to :student
  belongs_to :stat_type

  validates :target_value, presence: true, numericality: { greater_than: 0 }
  validates :target_date, presence: true
  validates :student_id, uniqueness: { scope: :stat_type_id }
end
