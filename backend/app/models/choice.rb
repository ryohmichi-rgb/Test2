class Choice < ApplicationRecord
  belongs_to :problem

  validates :text, presence: true
  validates :is_correct, inclusion: { in: [true, false] }
end
