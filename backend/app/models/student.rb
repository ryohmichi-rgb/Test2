class Student < ApplicationRecord
  has_many :answer_records, dependent: :destroy
  has_many :student_stats, dependent: :destroy
  has_many :goals, dependent: :destroy

  validates :name, presence: true

  def progress_for(unit)
    problems = unit.problems
    return { total: 0, correct: 0, accuracy: 0 } if problems.empty?

    answered = answer_records.where(problem: problems)
    correct = answered.where(is_correct: true).count
    total = answered.count

    { total: total, correct: correct, accuracy: total > 0 ? (correct.to_f / total * 100).round : 0 }
  end
end
