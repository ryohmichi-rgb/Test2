# 実績バッジの定義と判定。
#
# 定義をテーブルではなくコードに置いているのは、条件が「連続日数」「単元制覇」
# 「直近20問の正答率」のように列で表せないため。DBに残すのは獲得した事実だけ
# （StudentBadge）。
#
# `title` を持つバッジは、獲得すると**称号**としても名乗れる（ホームに表示）。
# ランク到達バッジに title を付けていないのは、ランク自体が別枠で表示されるため。
class BadgeCatalog
  Badge = Struct.new(:key, :label, :emoji, :title, :hint, keyword_init: true)

  RECENT_WINDOW = 20   # 「直近の正答率」を見る問題数
  ACCURACY_GOAL = 90   # その正答率のしきい値(%)

  ALL = [
    Badge.new(key: "first_step",       label: "はじめの一歩",   emoji: "🌱", hint: "1問正解する"),
    Badge.new(key: "ten_problems",     label: "10問クリア",     emoji: "✏️", hint: "10問正解する"),
    Badge.new(key: "fifty_problems",   label: "50問クリア",     emoji: "📚", hint: "50問正解する"),
    Badge.new(key: "hundred_problems", label: "100問クリア",    emoji: "🏆", hint: "100問正解する",
              title: "百問の達人"),
    Badge.new(key: "streak3",          label: "3日れんぞく",    emoji: "🔥", hint: "3日つづけて学習する"),
    Badge.new(key: "streak7",          label: "1週間れんぞく",  emoji: "⭐", hint: "7日つづけて学習する"),
    Badge.new(key: "streak30",         label: "1ヶ月れんぞく",  emoji: "🗓️", hint: "30日つづけて学習する",
              title: "継続の達人"),
    Badge.new(key: "perfect_test",     label: "テスト満点",     emoji: "💯", hint: "テストで100点を取る",
              title: "満点王"),
    Badge.new(key: "accuracy90",       label: "高い正答率",     emoji: "🎯",
              hint: "直近#{RECENT_WINDOW}問を#{ACCURACY_GOAL}%以上正解する", title: "せいかく職人"),
    Badge.new(key: "scholar",          label: "学びの人",       emoji: "🎓", hint: "解説を3つ読む"),
    Badge.new(key: "all_lessons",      label: "ぜんぶ読んだ",   emoji: "📖", hint: "すべての単元の解説を読む",
              title: "探究者"),
    Badge.new(key: "unit_master",      label: "単元制覇",       emoji: "🏅", hint: "ある単元の問題を全部正解する",
              title: "単元マスター"),
    Badge.new(key: "review_zero",      label: "復習ゼロ",       emoji: "✨", hint: "まちがえたままの問題をなくす"),
    Badge.new(key: "rank_1kyu",        label: "1級とうたつ",    emoji: "👑", hint: "1級に昇格する"),
    Badge.new(key: "rank_dan",         label: "初段とうたつ",   emoji: "🐉", hint: "初段に昇格する")
  ].freeze

  BY_KEY = ALL.index_by(&:key).freeze

  def self.find(key)
    BY_KEY[key.to_s]
  end

  # 称号を持つバッジだけ（称号の選択肢はここから作る）
  def self.with_title
    ALL.select(&:title)
  end

  def self.earned_keys_for(student)
    new(student).earned_keys
  end

  def initialize(student)
    @student = student
  end

  # 今の状態で条件を満たしているバッジの key（Set）
  def earned_keys
    keys = []
    keys << "first_step"       if total_correct >= 1
    keys << "ten_problems"     if total_correct >= 10
    keys << "fifty_problems"   if total_correct >= 50
    keys << "hundred_problems" if total_correct >= 100
    keys << "streak3"          if streak >= 3
    keys << "streak7"          if streak >= 7
    keys << "streak30"         if streak >= 30
    keys << "perfect_test"     if best_test_score >= 100
    keys << "accuracy90"       if recent_accuracy_reached?
    keys << "scholar"          if lessons_read >= 3
    keys << "all_lessons"      if all_lessons_read?
    keys << "unit_master"      if any_unit_mastered?
    keys << "review_zero"      if review_cleared?
    keys << "rank_1kyu"        if rank_reached?("1級")
    keys << "rank_dan"         if rank_reached?("初段")
    keys.to_set
  end

  private

  attr_reader :student

  def total_correct
    @total_correct ||= student.answer_records.where(is_correct: true).count
  end

  def streak
    @streak ||= student.study_streak
  end

  def best_test_score
    @best_test_score ||= student.test_results.maximum(:score_percent) || 0
  end

  def lessons_read
    @lessons_read ||= student.lesson_reads.count
  end

  def all_lessons_read?
    total_units = Unit.active_only.count
    total_units > 0 && lessons_read >= total_units
  end

  # 直近 RECENT_WINDOW 問の正答率。窓を埋めるだけ解いていなければ未達扱い
  # （3問中3問正解でバッジが出てしまうのを防ぐ）。
  def recent_accuracy_reached?
    recent = student.answer_records.order(created_at: :desc).limit(RECENT_WINDOW).pluck(:is_correct)
    return false if recent.size < RECENT_WINDOW
    (recent.count(true).to_f / recent.size * 100) >= ACCURACY_GOAL
  end

  # ひとつでも「その単元の有効な問題を全部正解した」単元があるか
  def any_unit_mastered?
    correct_ids = student.answer_records.where(is_correct: true).distinct.pluck(:problem_id).to_set
    return false if correct_ids.empty?

    Problem.active_only.pluck(:unit_id, :id)
      .group_by(&:first)
      .any? { |_unit_id, rows| rows.all? { |(_u, pid)| correct_ids.include?(pid) } }
  end

  # 復習リストが空か（＝最新の回答が不正解の問題がない）。ReviewController と同じ定義。
  # 一度も解いていない子が達成扱いにならないよう、回答が1件以上あることも要る。
  def review_cleared?
    latest_ids = student.answer_records.group(:problem_id).maximum(:id).values
    return false if latest_ids.empty?
    !AnswerRecord.where(id: latest_ids, is_correct: false).exists?
  end

  def rank_reached?(rank_name)
    target = Rank.find_by(name: rank_name)
    return false if target.nil?
    student.current_rank.display_order >= target.display_order
  end
end
