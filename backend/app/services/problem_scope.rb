# 範囲（学年 / ステータス / 単元）から問題セットを解決する共通ロジック。
# 問題集モードとテストモードの両方で使う。
#
# 教科は scope_type ではなく**別軸のしぼり込み**（subject_id）にしている。
# 「小6」を選んだときに算数と国語が混ざって出るのを防ぐのが目的で、これは
# 学年・ステータス・単元のどの範囲とも組み合わさるため。scope_type に足すと
# 「小6の算数」が表せない。
class ProblemScope
  attr_reader :scope_type, :scope_id, :subject_id

  def initialize(scope_type:, scope_id:, subject_id: nil)
    @scope_type = scope_type.to_s
    # scope_id は単一IDのほか、複数の単元IDの配列も受ける（昇格試験の「学んだ単元」用）。
    @scope_id = if scope_id.is_a?(Array)
      scope_id.map(&:to_i)
    else
      scope_id.presence && scope_id.to_i
    end
    @subject_id = subject_id.presence && subject_id.to_i
  end

  def valid?
    TestResult::SCOPE_TYPES.include?(scope_type) && units.exists?
  end

  # 生徒が実際に学んだ（1問以上答えた）単元だけを対象にするスコープ。昇格試験で使う。
  # 生徒に学年を持たせていないので、「まだ習っていない学年の問題が出る」のを
  # 学年ではなく学習履歴で防いでいる（先取りした分はちゃんと範囲に入る）。
  # subject_ids を渡すと、その教科の単元だけにしぼる（教科のまとまりごとの昇格試験で使う）。
  def self.learned_by(student, subject_ids = nil)
    rel = Unit.active_only
      .joins(problems: :answer_records)
      .where(answer_records: { student_id: student.id })
    rel = rel.where(subject_id: subject_ids) if subject_ids
    new(scope_type: "unit", scope_id: rel.distinct.pluck(:id))
  end

  # 全問を対象にするスコープ（今日の一問・ノルマの上限計算で使う）。
  # TestResult::SCOPE_TYPES には含めないので、テストや問題集の範囲としては選べない。
  def self.all_problems
    new(scope_type: "all", scope_id: nil)
  end

  def units
    @units ||= begin
      base = case scope_type
      when "grade"     then Unit.active_only.where(grade_id: scope_id)
      when "stat_type" then Unit.active_only.for_stat_type(scope_id)
      when "unit"      then Unit.active_only.where(id: scope_id)
      when "all"       then Unit.active_only
      else Unit.none
      end
      subject_id ? base.where(subject_id: subject_id) : base
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
  # 各段の中は**習熟度に応じた重みづけ**で並べ替え、上から順に count 問になるまで詰める。
  #
  # 優先度が先、難易度はその中での並べ替え、という順序が肝。逆にして先に難易度で
  # 絞ると「未挑戦かつ難易度3」が存在しない、という状況で候補がゼロになる。
  def sample_problems_for(student, count)
    count = count.to_i
    pool = problems.to_a
    return pool.shuffle if count <= 0 || count >= pool.size

    tiers = classify(student, pool)
    centers = center_difficulty_by_unit(student, pool)
    tiers.flat_map { |tier| weighted_shuffle(tier, centers) }.first(count)
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
    return "学んだ単元" if scope_id.is_a?(Array)

    base = case scope_type
    when "grade"     then Grade.find_by(id: scope_id)&.name.to_s
    when "stat_type" then "#{StatType.find_by(id: scope_id)&.name}テスト"
    when "unit"      then Unit.find_by(id: scope_id)&.title.to_s
    else ""
    end

    # 単元は名前から教科が分かるので付けない。教科を選んでいないとき（＝教科が1つしか
    # 無くて画面に出ていないとき）も、これまでどおり「小6」のままにする。
    return base if subject_id.nil? || scope_type == "unit"
    name = Subject.find_by(id: subject_id)&.name
    name.present? ? "#{name}｜#{base}" : base
  end

  # ===== 習熟度に応じた出題 =====
  #
  # 「その単元での直近の正答率」から中心難易度を決め、そこに近い問題を出やすくする。
  # 単元ごとに見るのは、得意・苦手が単元によって違うため（全体の正答率だと、得意分野で
  # 稼いだ数字で苦手分野にも難問が出てしまう）。はじめての単元はデータなし＝やさしめ。
  MASTERY_WINDOW      = 10  # その単元での直近何問を見るか
  MASTERY_MIN_SAMPLES = 3   # これ未満は「データなし」扱い
  DEFAULT_CENTER      = 1   # データがないときの中心難易度

  # 中心からの距離ごとの重み（距離0 / 1 / 2以上）。
  # 中心を厚くしつつ、どの難易度も出る余地は残す（ずっと同じ難易度だと飽きるため）。
  DIFFICULTY_WEIGHTS = [4, 2, 1].freeze

  def self.center_difficulty(accuracy)
    return DEFAULT_CENTER if accuracy.nil?

    case accuracy
    when 0...50  then 1
    when 50...70 then 2
    when 70...85 then 3
    when 85...95 then 4
    else              5
    end
  end

  # 単元ID => その単元での直近 MASTERY_WINDOW 問の正答率(%)。
  # 回答が MASTERY_MIN_SAMPLES 未満の単元は含めない（数問の偶然で難易度が飛ばないように）。
  def self.mastery_by_unit(student, unit_ids)
    return {} if student.nil? || unit_ids.empty?

    rows = AnswerRecord
      .joins(:problem)
      .where(student_id: student.id, problems: { unit_id: unit_ids })
      .order(created_at: :desc)
      .pluck("problems.unit_id", :is_correct)

    recent = Hash.new { |h, k| h[k] = [] }
    rows.each do |unit_id, correct|
      list = recent[unit_id]
      list << correct if list.size < MASTERY_WINDOW
    end

    recent.each_with_object({}) do |(unit_id, list), acc|
      next if list.size < MASTERY_MIN_SAMPLES
      acc[unit_id] = list.count(true).to_f / list.size * 100
    end
  end

  private

  def center_difficulty_by_unit(student, pool)
    mastery = self.class.mastery_by_unit(student, pool.map(&:unit_id).uniq)
    mastery.transform_values { |accuracy| self.class.center_difficulty(accuracy) }
  end

  # 重みつきのシャッフル。重い問題ほど前に来やすいが、順番は毎回変わる。
  # key = rand ** (1/weight) を降順に並べる方式（重みつき非復元抽出の定石）。
  def weighted_shuffle(list, centers)
    list.sort_by do |problem|
      center = centers[problem.unit_id] || DEFAULT_CENTER
      distance = (problem.difficulty.to_i - center).abs
      weight = DIFFICULTY_WEIGHTS[distance] || DIFFICULTY_WEIGHTS.last
      -(rand**(1.0 / weight))
    end
  end

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
