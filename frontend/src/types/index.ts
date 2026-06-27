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
