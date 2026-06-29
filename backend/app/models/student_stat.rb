class StudentStat < ApplicationRecord
  belongs_to :student
  belongs_to :stat_type

  validates :student_id, uniqueness: { scope: :stat_type_id }
  validates :value, numericality: { greater_than_or_equal_to: 0 }

  def self.for_student(student)
    StatType.all.map do |st|
      find_or_initialize_by(student: student, stat_type: st).tap do |ss|
        ss.value ||= 0
      end
    end
  end
end
