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
  grade?: Grade;
  subject?: Subject;
  problems?: Problem[];
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
  priority: number;
}

export interface LearningPlan {
  goals_summary: GoalSummary[];
  today_plan: PlanUnit[];
}
