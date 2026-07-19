class LessonRead < ApplicationRecord
  belongs_to :student
  belongs_to :unit

  validates :student_id, uniqueness: { scope: :unit_id }
end
