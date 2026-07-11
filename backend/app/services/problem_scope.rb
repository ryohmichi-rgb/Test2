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

  def units
    @units ||= case scope_type
    when "grade"     then Unit.where(grade_id: scope_id)
    when "stat_type" then Unit.where(stat_type_id: scope_id)
    when "unit"      then Unit.where(id: scope_id)
    else Unit.none
    end
  end

  # 範囲内の問題を count 問ランダムに抽出（count 未満なら全問）
  def sample_problems(count)
    pool = Problem.where(unit_id: units.select(:id)).includes(:choices).to_a
    count = count.to_i
    return pool.shuffle if count <= 0 || count >= pool.size
    pool.sample(count)
  end

  def available_count
    Problem.where(unit_id: units.select(:id)).count
  end

  def label
    case scope_type
    when "grade"     then Grade.find_by(id: scope_id)&.name.to_s
    when "stat_type" then "#{StatType.find_by(id: scope_id)&.name}テスト"
    when "unit"      then Unit.find_by(id: scope_id)&.title.to_s
    else ""
    end
  end
end
