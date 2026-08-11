# 保護者と子どもの紐づけ。管理画面から作る（招待コードの仕組みは持たない）。
class Guardianship < ApplicationRecord
  belongs_to :guardian, class_name: "Student"
  belongs_to :student

  validates :student_id, uniqueness: { scope: :guardian_id }
  validate :guardian_must_be_parent
  validate :student_must_not_be_parent
  validate :cannot_guard_self

  private

  def guardian_must_be_parent
    errors.add(:guardian, "は保護者アカウントではありません") unless guardian&.parent?
  end

  def student_must_not_be_parent
    errors.add(:student, "に保護者アカウントは指定できません") if student&.parent?
  end

  def cannot_guard_self
    errors.add(:student, "に自分自身は指定できません") if guardian_id.present? && guardian_id == student_id
  end
end
