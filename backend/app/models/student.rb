class Student < ApplicationRecord
  has_secure_password

  has_many :answer_records, dependent: :destroy
  has_many :student_stats, dependent: :destroy
  has_many :goals, dependent: :destroy
  has_many :test_results, dependent: :destroy
  has_many :lesson_reads, dependent: :destroy

  validates :name, presence: true
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 4 }, allow_nil: true

  # 署名付き認証トークン（パスワード変更で自動失効・30日有効）
  generates_token_for :auth, expires_in: 30.days do
    password_salt&.last(10)
  end

  def progress_for(unit)
    problems = unit.problems
    return { total: 0, correct: 0, accuracy: 0 } if problems.empty?

    answered = answer_records.where(problem: problems)
    correct = answered.where(is_correct: true).count
    total = answered.count

    { total: total, correct: correct, accuracy: total > 0 ? (correct.to_f / total * 100).round : 0 }
  end

  # 学習した日の連続数（今日やっていれば今日から、まだなら昨日から数える）
  def study_streak(today = Date.current)
    dates = answer_records.pluck(:created_at).map(&:to_date).uniq.to_set
    start = dates.include?(today) ? today : today - 1
    count = 0
    d = start
    while dates.include?(d)
      count += 1
      d -= 1
    end
    count
  end
end
