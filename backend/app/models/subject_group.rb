# ランクを数える単位。教科そのものではなく「まとまり」にしている。
#
# 算数（小6）と数学（中1）は学年と1対1で、実質ひとつながりの積み上げ。教科で割ると
# 中1に進んだ時点で算数のランクが止まり、数学は10級からやり直しになってしまう。
# 国語のように別系統の教科を足したら、そちらは別のまとまりにする。
class SubjectGroup < ApplicationRecord
  has_many :subjects, dependent: :nullify
  has_many :student_ranks, dependent: :destroy

  validates :name, presence: true

  scope :ordered, -> { order(:display_order, :id) }

  # いま出題できる（有効な単元がある）まとまりだけ。ランクを出すのはこれ。
  def self.active
    ordered.where(id: Subject.where(id: Unit.where(active: true).select(:subject_id)).select(:subject_group_id))
  end

  def unit_ids
    Unit.active_only.where(subject_id: subjects.select(:id)).select(:id)
  end
end
