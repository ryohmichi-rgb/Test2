class Problem < ApplicationRecord
  belongs_to :unit
  has_many :choices, dependent: :destroy
  has_many :answer_records, dependent: :destroy

  validates :question, presence: true
  validates :answer, presence: true
  validates :difficulty, numericality: { in: 1..5 }
  validates :problem_type, inclusion: { in: %w[fill_in multiple_choice] }

  scope :by_difficulty, -> { order(:difficulty) }
end
