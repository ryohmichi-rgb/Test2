class Subject < ApplicationRecord
  has_many :units, dependent: :destroy
  # ランクを数える単位。指定しなければ、その教科だけの新しいまとまりを作る
  # （新しい教科は別系統のことが多い。同じ積み上げに混ぜたいときは管理画面で選ぶ）。
  belongs_to :subject_group, optional: true

  validates :name, presence: true, uniqueness: true

  before_validation :ensure_subject_group, on: :create

  private

  def ensure_subject_group
    return if subject_group_id.present? || subject_group.present?
    self.subject_group = SubjectGroup.new(name: name, display_order: (SubjectGroup.maximum(:display_order) || -1) + 1)
  end
end
