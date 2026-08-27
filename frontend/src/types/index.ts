export interface Grade {
  id: number;
  name: string;
  display_order: number;
  units: Unit[];
}

export interface Subject {
  id: number;
  name: string;
}

export interface Unit {
  id: number;
  title: string;
  description: string;
  display_order: number;
  lesson_body?: string;
  /** この単元が伸ばすステータス（複数可）。ステータス別の範囲を教科でしぼるのに使う */
  stat_type_ids?: number[];
  grade?: Grade;
  subject?: Subject;
  problems?: Problem[];
}

export interface LessonReadResult {
  awarded: boolean;
  points: number;
}

export interface Badge {
  key: string;
  label: string;
  emoji: string;
  /** 獲得のしかた（未獲得のバッジで「あと何をすれば」を見せる） */
  hint: string;
  /** 称号を持つバッジなら称号名。持たなければ null */
  title: string | null;
  earned: boolean;
  earned_at: string | null;
}

/** 称号の選択肢（称号を持つバッジだけ） */
export interface TitleOption {
  key: string;
  title: string;
  label: string;
  emoji: string;
  hint: string;
  earned: boolean;
}

export interface Achievements {
  badges: Badge[];
  /** この取得で新たに獲得したバッジ（お祝い用） */
  newly_earned: string[];
  title_key: string | null;
  title: string | null;
  titles: TitleOption[];
}

export interface Rank {
  id: number;
  name: string;
  threshold_points: number;
  display_order: number;
}

/** 総合ランクの状況（昇格試験に挑戦できるかどうかを含む） */
export interface RankStatus {
  current_rank: Rank;
  next_rank: Rank | null;
  total_points: number;
  points_to_next: number;
  /** 次のランクのしきい値に届いているか */
  reached: boolean;
  /** 再挑戦までに必要な残りポイント（0なら待ちなし） */
  retry_points_needed: number;
  /** いま昇格試験に挑戦できるか */
  available: boolean;
  question_count: number;
  pass_percent: number | null;
  scope_label: string;
}

export interface PromotionExamSet {
  rank: Rank;
  pass_percent: number;
  scope_label: string;
  problems: Problem[];
}

export interface PromotionExamResult {
  passed: boolean;
  score_percent: number;
  correct_count: number;
  total_questions: number;
  answers: { problem_id: number; is_correct: boolean; correct_answer: string }[];
  status: RankStatus;
}

export interface Condition {
  rust_percent: number;
  idle_days: number;
  last_studied_on: string | null;
}

export interface Choice {
  id: number;
  text: string;
}

export interface Problem {
  id: number;
  question: string;
  hint: string;
  difficulty: number;
  problem_type: "fill_in" | "multiple_choice";
  choices?: Choice[];
}

export type AskKind = "hint" | "approach" | "why" | "free";
/** 「この人に聞く」の質問の種類 */
export type PersonaKind = "why_study" | "how_used" | "childhood" | "free";

export interface AiUsage {
  used: number;
  limit: number;
  remaining: number;
}

export interface AskTeacherResult extends AiUsage {
  answer: string | null;
  error?: string;
  exhausted?: boolean;
}

export interface Student {
  id: number;
  name: string;
  username?: string;
  /** アカウントの種類。"parent" なら保護者（見る専用） */
  role?: "student" | "parent";
  /** 自分を見ている保護者（黙って見られている状態にしないため本人にも見せる） */
  guardians?: { id: number; name: string }[];
  onboarded?: boolean;
  admin?: boolean;
}

/** 保護者が見られる子ども（一覧用のサマリー） */
export interface Child {
  id: number;
  name: string;
  username: string;
  total_points: number;
  rank: string | null;
  streak: number;
  last_studied_on: string | null;
}

export interface AdminMeta {
  grades: { id: number; name: string }[];
  subjects: { id: number; name: string }[];
  stat_types: { id: number; name: string }[];
}

export interface AdminSubject {
  id: number;
  name: string;
  unit_count: number;
  /** 単元がぶら下がっているか。true なら削除できない */
  used: boolean;
}

export interface AdminUnit {
  id: number;
  title: string;
  description: string;
  lesson_body: string;
  display_order: number;
  active: boolean;
  grade_id: number;
  grade: string;
  subject_id: number;
  subject: string;
  /** この単元が伸ばすステータス（複数可）。ポイントは均等に分けて入る */
  stat_type_ids: number[];
  stat_types: string[];
  problem_count: number;
  used: boolean;
}

export interface AdminChoice {
  id?: number;
  text: string;
  is_correct: boolean;
}

export interface AdminProblem {
  id: number;
  unit_id: number;
  question: string;
  answer: string;
  hint: string;
  /** 間違えたときに出す解き方。空なら何も出ない */
  solution: string;
  difficulty: number;
  problem_type: "fill_in" | "multiple_choice";
  active: boolean;
  used: boolean;
  choices: AdminChoice[];
}

export interface AdminReferenceStat {
  id: number;
  label: string;
  stat_type_id: number;
  stat_type: string;
  value: number;
}

export interface AdminStudentSummary {
  id: number;
  name: string;
  username: string;
  role: "student" | "parent";
  /** 保護者なら見ている子ども / 生徒なら見ている保護者 */
  children: { id: number; name: string }[];
  guardians: { id: number; name: string }[];
  admin: boolean;
  onboarded: boolean;
  created_at: string;
  correct_count: number;
  last_studied_on: string | null;
}

export interface AuthResult {
  token: string;
  student: Student;
}

export interface AnswerResult {
  is_correct: boolean;
  correct_answer: string;
  explanation: string;
  /** 解き方の解説。間違えたときだけ入る（正解時と、解説が未登録の問題では null） */
  solution: string | null;
  points: number;
  /** 同じ問題の解き直しでポイントが減額されたか（黙って減らさず知らせる） */
  is_repeat: boolean;
}

export interface UnitProgress {
  unit_id: number;
  unit_title: string;
  grade: string;
  subject: string;
  total_problems: number;
  answered: number;
  correct: number;
  accuracy: number;
}

export interface StudentProgress {
  student: Student;
  progress: UnitProgress[];
}

export interface StatGoal {
  target_value: number;
  target_date: string;
}

export interface StudentStat {
  stat_type_id: number;
  name: string;
  description: string;
  display_order: number;
  value: number;
  goal: StatGoal | null;
}

export interface ReferenceStat {
  label: string;
  stats: { stat_type_id: number; name: string; value: number }[];
}

export interface GoalSummary {
  stat_type_id: number;
  stat_name: string;
  current: number;
  target: number;
  target_date: string;
  days_remaining: number;
  points_needed: number;
  points_per_day: number;
  achieved: boolean;
}

export interface PlanUnit {
  unit_id: number;
  unit_title: string;
  stat_name: string;
  stat_type_id: number;
  accuracy: number | null;
  total_answered: number;
  estimated_points: number;
  is_new: boolean;
  lesson_read: boolean;
  priority: number;
}

export interface LearningPlan {
  goals_summary: GoalSummary[];
  today_plan: PlanUnit[];
}

export type ScopeType = "grade" | "stat_type" | "unit";

export interface ProblemSet {
  scope_type: ScopeType;
  scope_id: number | null;
  /** 範囲とは別軸の教科しぼり込み。教科が1つしか無いうちは null */
  subject_id: number | null;
  scope_label: string;
  available_count: number;
  problems: Problem[];
}

export interface TestResult {
  id: number;
  scope_type: ScopeType;
  scope_id: number | null;
  subject_id: number | null;
  scope_label: string;
  total_questions: number;
  correct_count: number;
  score_percent: number;
  rank: string;
  created_at: string;
}

export interface TestSubmitResult extends TestResult {
  bonus_points: number;
  is_best: boolean;
  previous_score: number | null;
  answers: { problem_id: number; is_correct: boolean; correct_answer: string }[];
}

export interface GrowthSeries {
  stat_name: string;
  actual: number[];
  target: number[];
}

export interface Growth {
  labels_actual: string[];
  labels_target: string[];
  total: { actual: number[]; target: number[] };
  by_stat: GrowthSeries[];
}

export interface DailyQuota {
  target_points: number;
  earned_points: number;
  approx_problems: number;
  studied_today: boolean;
  /** 学習した日の連続数 */
  streak: number;
  /** ノルマを達成した日の連続数（学習日の連続とは別枠。解ける問題が尽きた日は飛ばす） */
  quota_streak: number;
  has_goal: boolean;
  /** 満点で解ける問題が尽きた状態（全問を最近やりきった） */
  exhausted: boolean;
  /** 復帰待ちの問題数（「あと○問もどってくる」の表示用） */
  returning_count: number;
}

export interface ReviewList {
  count: number;
  problems: Problem[];
}
