class AnswerRecord < ApplicationRecord
  belongs_to :student
  belongs_to :problem

  validates :submitted_answer, presence: true
  validates :is_correct, inclusion: { in: [true, false] }

  before_validation :evaluate_answer, on: :create

  private

  def evaluate_answer
    self.is_correct = submitted_answer.to_s.strip == problem.answer.to_s.strip if problem
  end
end
