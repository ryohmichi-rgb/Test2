class AnswerRecord < ApplicationRecord
  belongs_to :student
  belongs_to :problem

  validates :submitted_answer, presence: true
  validates :is_correct, inclusion: { in: [true, false] }

  before_validation :evaluate_answer, on: :create
  after_create :update_student_stat, if: :is_correct?

  POINTS_BY_DIFFICULTY = { 1 => 10, 2 => 15, 3 => 20 }.freeze

  private

  def evaluate_answer
    self.is_correct = submitted_answer.to_s.strip == problem.answer.to_s.strip if problem
  end

  def update_student_stat
    stat_type = problem.unit.stat_type
    return unless stat_type

    points = POINTS_BY_DIFFICULTY[problem.difficulty] || 10
    stat = StudentStat.find_or_initialize_by(student: student, stat_type: stat_type)
    stat.value = (stat.value || 0) + points
    stat.save!
  end
end
