# 生徒の「教科のまとまり」ごとのランク。
# rank が nil の行は最下位ランク扱い（students.rank_id が NULL のときと同じ考え方）。
class StudentRank < ApplicationRecord
  belongs_to :student
  belongs_to :subject_group
  belongs_to :rank, optional: true

  validates :student_id, uniqueness: { scope: :subject_group_id }

  def self.for(student, group)
    find_or_create_by!(student: student, subject_group: group)
  end
end
