# 昇格試験。総合ランクは「合計ポイントで到達 → 試験に合格」で上がる。
#
# 出題範囲は**その子が学んだ単元**（ProblemScope.learned_by）。生徒に学年を持たせて
# いないので、未学習の学年から出題されるのを学習履歴で防いでいる。
#
# 落ちたときの再挑戦は「そこから RETRY_POINTS だけ伸ばす」。
# 注意: 試験の回答も AnswerRecord を通るのでポイントが入る。スナップショット
# （last_exam_points）は**採点が終わって加点が反映されたあと**に取ること。先に取ると
# 試験自身の得点で条件を満たしてしまい、落ちた直後に再挑戦できてしまう。
class PromotionExam
  RETRY_POINTS = 20

  # 昇格試験のポイント報酬は「ランクが上がること」そのもの。テストの高得点ボーナスは
  # 付けない（付けると再挑戦のしきい値と絡んで挙動が読みにくくなる）。
  BONUS_POINTS = 0

  class NotAvailable < StandardError; end

  def initialize(student)
    @student = student
  end

  attr_reader :student

  def current_rank = student.current_rank
  def next_rank    = current_rank.next_rank
  def total_points = student.total_points

  # 次のランクのしきい値に届いているか
  def reached?
    next_rank.present? && total_points >= next_rank.threshold_points
  end

  # 再挑戦までに必要な残りポイント（0 なら待ちなし）
  def retry_points_needed
    return 0 if student.last_exam_points.nil?
    [student.last_exam_points + RETRY_POINTS - total_points, 0].max
  end

  def available?
    reached? && retry_points_needed.zero? && problem_pool.any?
  end

  def scope
    @scope ||= ProblemScope.learned_by(student)
  end

  def problem_pool
    @problem_pool ||= scope.problems.to_a
  end

  def question_count
    [next_rank&.exam_question_count.to_i, problem_pool.size].min
  end

  def problems
    raise NotAvailable, "いまは昇格試験に挑戦できません。" unless available?
    scope.sample_problems(next_rank.exam_question_count)
  end

  def status
    {
      current_rank: serialize_rank(current_rank),
      next_rank: serialize_rank(next_rank),
      total_points: total_points,
      points_to_next: next_rank ? [next_rank.threshold_points - total_points, 0].max : 0,
      reached: reached?,
      retry_points_needed: retry_points_needed,
      available: available?,
      question_count: question_count,
      pass_percent: next_rank&.pass_percent,
      scope_label: scope.label
    }
  end

  # 採点して昇格判定まで行う。
  # graded: [{ is_correct: bool }, ...]（AnswerRecord は呼び出し側で作成ずみ）
  def finish!(graded)
    target = next_rank
    raise NotAvailable, "昇格できるランクがありません。" if target.nil?

    total = graded.size
    correct = graded.count { |g| g[:is_correct] }
    score = total > 0 ? (correct.to_f / total * 100).round : 0
    passed = score >= target.pass_percent

    result = student.test_results.create!(
      scope_type: "promotion",
      scope_id: target.id,
      scope_label: "昇格試験（#{target.name}）",
      total_questions: total,
      correct_count: correct,
      score_percent: score,
      bonus_points: BONUS_POINTS
    )

    if passed
      student.update!(rank: target, last_exam_points: nil)
    else
      # ここは加点が終わったあと。試験自身の得点を含んだ合計を基準にすることで、
      # 追加の RETRY_POINTS は必ず試験の外で稼ぐことになる。
      student.update!(last_exam_points: student.reload.total_points)
    end

    { result: result, passed: passed, score_percent: score, correct_count: correct, total_questions: total }
  end

  private

  def serialize_rank(rank)
    return nil if rank.nil?
    { id: rank.id, name: rank.name, threshold_points: rank.threshold_points, display_order: rank.display_order }
  end
end
