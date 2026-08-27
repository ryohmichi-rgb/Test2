class AnswerRecord < ApplicationRecord
  belongs_to :student
  belongs_to :problem

  validates :submitted_answer, presence: true
  validates :is_correct, inclusion: { in: [true, false] }

  before_validation :evaluate_answer, on: :create
  before_validation :assign_points, on: :create
  after_create :update_student_stat, if: :is_correct?
  after_create :record_daily_quota

  POINTS_BY_DIFFICULTY = { 1 => 10, 2 => 15, 3 => 20, 4 => 25, 5 => 30 }.freeze
  DEFAULT_POINTS = 10

  # farming対策：同じ問題を解き直したときの扱い。
  # - 初回の正解は満点
  # - 前回正解から RECOVERY_DAYS 未満での解き直しは満点の REPEAT_RATE（最低1pt）
  # - RECOVERY_DAYS 以上あいていれば満点に復帰（忘れた頃の復習は正しく評価する）
  #
  # ポイントは回答時に確定して points_awarded に保存する。あとから再計算すると
  # 過去の成長曲線まで書き変わってしまうため。読み出し側（成長曲線・今日のノルマ）は
  # このカラムを SUM するだけでよい。
  #
  # RECOVERY_DAYS は出題の重複回避（ProblemScope）でも同じ基準として使う。
  REPEAT_RATE       = 0.2
  RECOVERY_DAYS     = 14
  MIN_REPEAT_POINTS = 1

  # 満点（難易度別）
  def self.full_points_for(difficulty)
    POINTS_BY_DIFFICULTY[difficulty] || DEFAULT_POINTS
  end

  # 一括提出（テスト・昇格試験）で空欄のまま出されたときの記録内容。
  # 制限時間切れの自動提出や、わからない問題を飛ばした場合に起きる。
  # submitted_answer は presence 必須なので、空欄をそのまま渡すと 500 になってしまう。
  # 「答えなかった」＝不正解として残すのが実態に合う。
  # （1問ずつ答える通常経路では空欄はクライアント側のバグなので、従来どおり弾く）
  BLANK_ANSWER = "（未回答）".freeze

  def self.normalize_submitted(value)
    text = value.to_s.strip
    text.empty? ? BLANK_ANSWER : text
  end

  # この回答が「解き直し」で減額されたか（フィードバック表示に使う）
  def repeat?
    return false unless is_correct? && problem
    points_awarded.to_i < self.class.full_points_for(problem.difficulty)
  end

  private

  def evaluate_answer
    self.is_correct = submitted_answer.to_s.strip == problem.answer.to_s.strip if problem
  end

  def assign_points
    self.points_awarded = (is_correct? && problem) ? points_for_this_answer : 0
  end

  def points_for_this_answer
    full = self.class.full_points_for(problem.difficulty)
    last = last_correct_at
    return full if last.nil? || last <= RECOVERY_DAYS.days.ago

    [(full * REPEAT_RATE).round, MIN_REPEAT_POINTS].max
  end

  # この生徒がこの問題を前回正解した日時（今回の回答はまだ未保存なので含まれない）
  def last_correct_at
    AnswerRecord
      .where(student_id: student_id, problem_id: problem_id, is_correct: true)
      .maximum(:created_at)
  end

  # その日のノルマを必ず残す。ホームを開かずに問題だけ解いた日でも、
  # あとから「ノルマを達成した日」かどうかを判定できるようにするため
  # （ノルマは goals の履歴が無いので、その日のうちに残さないと復元できない）。
  # 2問目からは既存行が見つかるだけなので、索引1回ぶんの負担で済む。
  def record_daily_quota
    DailyQuota.for(student, created_at.to_date)
  end

  # 単元が複数のステータスを伸ばすなら、ポイントを均等に分けて入れる。
  # 合計は元のポイントのまま（total_points が総合ランクの判定軸なので増減させない）。
  def update_student_stat
    return if points_awarded.to_i.zero?

    StatPoints.split(points_awarded, problem.unit.stat_type_ids).each do |stat_type_id, pts|
      stat = StudentStat.find_or_initialize_by(student: student, stat_type_id: stat_type_id)
      stat.value = (stat.value || 0) + pts
      stat.save!
    end
  end
end
