class Unit < ApplicationRecord
  belongs_to :grade
  belongs_to :subject
  belongs_to :stat_type, optional: true
  has_many :problems, dependent: :destroy

  validates :title, presence: true
  validates :display_order, presence: true

  scope :ordered, -> { order(:display_order) }
end
