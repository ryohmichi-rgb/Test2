class Problem < ApplicationRecord
  belongs_to :unit
  # 並びを id 順に固定する。選択肢は「正解の位置がかたよらないように」順番を決めて
  # seed に書いているので、DBの返す順まかせにすると意図した並びにならない。
  has_many :choices, -> { order(:id) }, dependent: :destroy
  has_many :answer_records, dependent: :destroy

  validates :question, presence: true
  validates :answer, presence: true
  validates :difficulty, numericality: { in: 1..5 }
  validates :problem_type, inclusion: { in: %w[fill_in multiple_choice] }

  scope :by_difficulty, -> { order(:difficulty) }
  scope :active_only, -> { where(active: true) }
end
