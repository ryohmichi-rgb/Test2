# 範囲（学年 / ステータス / 単元）から問題セットを解決する共通ロジック。
# 問題集モードとテストモードの両方で使う。
class ProblemScope
  attr_reader :scope_type, :scope_id

  def initialize(scope_type:, scope_id:)
    @scope_type = scope_type.to_s
    @scope_id = scope_id.presence && scope_id.to_i
  end

  def valid?
    TestResult::SCOPE_TYPES.include?(scope_type) && units.exists?
  end

  # 全問を対象にするスコープ（今日の一問・ノルマの上限計算で使う）。
  # TestResult::SCOPE_TYPES には含めないので、テストや問題集の範囲としては選べない。
  def self.all_problems
    new(scope_type: "all", scope_id: nil)
  end

  def units
    @units ||= case scope_type
    when "grade"     then Unit.active_only.where(grade_id: scope_id)
    when "stat_type" then Unit.active_only.where(stat_type_id: scope_id)
    when "unit"      then Unit.active_only.where(id: scope_id)
    when "all"       then Unit.active_only
    else Unit.none
    end
  end

  # 範囲内の問題を count 問ランダムに抽出（count 未満なら全問）。
  # テストはこちらを使う（実力測定なので、解ける問題も含めて範囲全体から出す）。
  def sample_problems(count)
    pool = problems.to_a
    count = count.to_i
    return pool.shuffle if count <= 0 || count >= pool.size
    pool.sample(count)
  end

  # 練習用（問題集・今日の一問）の出題。同じ問題ばかり出ないよう優先度をつけて選ぶ。
  #   1. 未挑戦
  #   2. 最新の回答が不正解（＝復習すべき問題）
  #   3. 正解済みだが RECOVERY_DAYS 以上たっている（満点に復帰している）
  #   4. 正解済みで RECOVERY_DAYS 以内（最後の手段。加点も20%になる）
  # 各段の中はシャッフルし、上から順に count 問になるまで詰める。
  def sample_problems_for(student, count)
    count = count.to_i
    pool = problems.to_a
    return pool.shuffle if count <= 0 || count >= pool.size

    tiers = classify(student, pool)
    tiers.flat_map(&:shuffle).first(count)
  end

  # 今「満点」で解ける問題（未挑戦・要復習・回復済み）。
  # 今日のノルマの上限を決めるのに使う。
  def full_point_problems_for(student)
    untried, wrong, recovered, = classify(student, problems.to_a)
    untried + wrong + recovered
  end

  def available_count
    problems.count
  end

  def problems
    Problem.active_only.where(unit_id: units.select(:id)).includes(:choices)
  end

  def label
    case scope_type
    when "grade"     then Grade.find_by(id: scope_id)&.name.to_s
    when "stat_type" then "#{StatType.find_by(id: scope_id)&.name}テスト"
    when "unit"      then Unit.find_by(id: scope_id)&.title.to_s
    else ""
    end
  end

  private

  # 問題を4つの層に振り分ける（上記 sample_problems_for のコメント参照）
  def classify(student, pool)
    latest = latest_answers_for(student, pool.map(&:id))
    threshold = AnswerRecord::RECOVERY_DAYS.days.ago

    untried, wrong, recovered, recent = [], [], [], []
    pool.each do |problem|
      state = latest[problem.id]
      if state.nil?
        untried << problem
      elsif !state[:is_correct]
        wrong << problem
      elsif state[:last_correct_at].nil? || state[:last_correct_at] <= threshold
        recovered << problem
      else
        recent << problem
      end
    end
    [untried, wrong, recovered, recent]
  end

  # 問題ごとに「最新の回答が正解か」と「最後に正解した日時」をまとめて引く
  def latest_answers_for(student, problem_ids)
    return {} if student.nil? || problem_ids.empty?

    records = AnswerRecord
      .where(student_id: student.id, problem_id: problem_ids)
      .order(:created_at)
      .pluck(:problem_id, :is_correct, :created_at)

    records.each_with_object({}) do |(pid, correct, at), acc|
      entry = acc[pid] ||= { is_correct: false, last_correct_at: nil }
      entry[:is_correct] = correct              # 最後に見たものが最新（created_at 昇順のため）
      entry[:last_correct_at] = at if correct
    end
  end
end
