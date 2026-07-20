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
  earned: boolean;
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

export interface Student {
  id: number;
  name: string;
  username?: string;
  onboarded?: boolean;
  admin?: boolean;
}

export interface AdminMeta {
  grades: { id: number; name: string }[];
  subjects: { id: number; name: string }[];
  stat_types: { id: number; name: string }[];
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
  stat_type_id: number | null;
  stat_type: string | null;
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
  scope_label: string;
  available_count: number;
  problems: Problem[];
}

export interface TestResult {
  id: number;
  scope_type: ScopeType;
  scope_id: number | null;
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
  streak: number;
  has_goal: boolean;
}

export interface ReviewList {
  count: number;
  problems: Problem[];
}
