class Grade < ApplicationRecord
  has_many :units, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :display_order, presence: true

  scope :ordered, -> { order(:display_order) }
end
