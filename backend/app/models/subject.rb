class Subject < ApplicationRecord
  has_many :units, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
