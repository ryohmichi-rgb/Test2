# 「教科のまとまり」ごとに積み上げたポイント。ランクの判定軸。
#
# student_stats はステータス別の現在値しか持たず、教科の軸を持たない。そこで
# 成長曲線と同じ3系統（回答・テストのボーナス・教材の読了）を、まとまりで束ねて数える。
#
# **有効・無効や、いま付いているステータスでは絞らない。** 単元を無効化したり
# ステータスの紐づけを外したりしたときに、過去に積んだポイントが消えてランクが
# 下がって見えるのを防ぐため（降格はしない、という約束を読み出し側でも守る）。
module RankPoints
  # student => { subject_group_id => points }
  def self.by_group(student)
    acc = Hash.new(0)

    # 1. 問題の正解（points_awarded は回答時に確定ずみ）
    student.answer_records
      .where(is_correct: true)
      .joins(problem: { unit: :subject })
      .group("subjects.subject_group_id")
      .sum(:points_awarded)
      .each { |gid, pts| acc[gid] += pts.to_i if gid }

    # 2. 教材の初回読了
    student.lesson_reads
      .joins(unit: :subject)
      .group("subjects.subject_group_id")
      .count
      .each { |gid, n| acc[gid] += n * LessonRead::POINTS if gid }

    # 3. テストの高得点ボーナス
    student.test_results.where("bonus_points > 0").find_each do |t|
      gids = group_ids_for(t)
      next if gids.empty?
      base, remainder = t.bonus_points.to_i.divmod(gids.size)
      gids.each_with_index { |gid, i| acc[gid] += base + (i < remainder ? 1 : 0) }
    end

    acc
  end

  def self.for(student, group)
    by_group(student)[group.id].to_i
  end

  # そのテストのボーナスがどのまとまりに入るか。
  # 教科を選んで受けたテストはその教科。選んでいなければ範囲の単元からたどる。
  def self.group_ids_for(test_result)
    if test_result.subject_id
      return Subject.where(id: test_result.subject_id).pluck(:subject_group_id).compact.uniq.sort
    end

    unit_ids = ProblemScope
      .new(scope_type: test_result.scope_type, scope_id: test_result.scope_id)
      .units.select(:id)
    Subject.where(id: Unit.where(id: unit_ids).select(:subject_id))
      .pluck(:subject_group_id).compact.uniq.sort
  end
end
