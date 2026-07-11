import api from "./client";
import type { Grade, Unit, Student, AnswerResult, StudentProgress, StudentStat, ReferenceStat, LearningPlan, ScopeType, ProblemSet, TestResult, TestSubmitResult } from "../types";

export const fetchGrades = (): Promise<Grade[]> =>
  api.get<Grade[]>("/grades").then((r) => r.data);

export const fetchUnit = (id: number): Promise<Unit> =>
  api.get<Unit>(`/units/${id}`).then((r) => r.data);

export const createStudent = (name: string): Promise<Student> =>
  api.post<Student>("/students", { student: { name } }).then((r) => r.data);

export const fetchStudent = (id: number): Promise<Student> =>
  api.get<Student>(`/students/${id}`).then((r) => r.data);

export const fetchStudentProgress = (id: number): Promise<StudentProgress> =>
  api.get<StudentProgress>(`/students/${id}/progress`).then((r) => r.data);

export const fetchStudentStats = (id: number): Promise<StudentStat[]> =>
  api.get<StudentStat[]>(`/students/${id}/stats`).then((r) => r.data);

export const updateGoal = (
  studentId: number,
  statTypeId: number,
  targetValue: number,
  targetDate: string
): Promise<void> =>
  api.put(`/students/${studentId}/goals`, {
    goal: { stat_type_id: statTypeId, target_value: targetValue, target_date: targetDate },
  }).then(() => undefined);

export const fetchReferenceStats = (): Promise<ReferenceStat[]> =>
  api.get<ReferenceStat[]>("/reference_stats").then((r) => r.data);

export const fetchLearningPlan = (studentId: number): Promise<LearningPlan> =>
  api.get<LearningPlan>(`/students/${studentId}/plan`).then((r) => r.data);

export const fetchProblemSet = (
  scopeType: ScopeType,
  scopeId: number | null,
  count: number
): Promise<ProblemSet> =>
  api
    .get<ProblemSet>("/problem_set", { params: { scope_type: scopeType, scope_id: scopeId, count } })
    .then((r) => r.data);

export const submitTest = (
  studentId: number,
  scopeType: ScopeType,
  scopeId: number | null,
  answers: { problem_id: number; submitted_answer: string }[]
): Promise<TestSubmitResult> =>
  api
    .post<TestSubmitResult>(`/students/${studentId}/test_results`, {
      scope_type: scopeType,
      scope_id: scopeId,
      answers,
    })
    .then((r) => r.data);

export const fetchTestResults = (studentId: number): Promise<TestResult[]> =>
  api.get<TestResult[]>(`/students/${studentId}/test_results`).then((r) => r.data);

export const submitAnswer = (
  studentId: number,
  problemId: number,
  submittedAnswer: string
): Promise<AnswerResult> =>
  api
    .post<AnswerResult>("/answer_records", {
      answer_record: {
        student_id: studentId,
        problem_id: problemId,
        submitted_answer: submittedAnswer,
      },
    })
    .then((r) => r.data);
