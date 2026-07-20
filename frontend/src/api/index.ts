import api from "./client";
import type { Grade, Unit, Student, AuthResult, AnswerResult, StudentProgress, StudentStat, ReferenceStat, LearningPlan, ScopeType, ProblemSet, TestResult, TestSubmitResult, Growth, ReviewList, DailyQuota, LessonReadResult, Problem, Badge, Condition, AdminMeta, AdminUnit, AdminProblem, AdminChoice, AdminReferenceStat, AdminStudentSummary } from "../types";

export const fetchGrades = (): Promise<Grade[]> =>
  api.get<Grade[]>("/grades").then((r) => r.data);

export const fetchUnit = (id: number): Promise<Unit> =>
  api.get<Unit>(`/units/${id}`).then((r) => r.data);

export const signup = (name: string, username: string, password: string): Promise<AuthResult> =>
  api.post<AuthResult>("/signup", { name, username, password }).then((r) => r.data);

export const login = (username: string, password: string): Promise<AuthResult> =>
  api.post<AuthResult>("/login", { username, password }).then((r) => r.data);

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

export const fetchGrowth = (studentId: number): Promise<Growth> =>
  api.get<Growth>(`/students/${studentId}/growth`).then((r) => r.data);

export const fetchReviewList = (studentId: number): Promise<ReviewList> =>
  api.get<ReviewList>(`/students/${studentId}/review`).then((r) => r.data);

export const fetchDailyQuota = (studentId: number): Promise<DailyQuota> =>
  api.get<DailyQuota>(`/students/${studentId}/quota`).then((r) => r.data);

export const fetchLessonReads = (studentId: number): Promise<number[]> =>
  api.get<{ unit_ids: number[] }>(`/students/${studentId}/lesson_reads`).then((r) => r.data.unit_ids);

export const markLessonRead = (studentId: number, unitId: number): Promise<LessonReadResult> =>
  api.post<LessonReadResult>(`/students/${studentId}/lesson_reads`, { unit_id: unitId }).then((r) => r.data);

export const fetchDailyProblem = (studentId: number): Promise<Problem | null> =>
  api.get<{ problem: Problem | null }>(`/students/${studentId}/daily_problem`).then((r) => r.data.problem);

export const fetchAchievements = (studentId: number): Promise<Badge[]> =>
  api.get<{ badges: Badge[] }>(`/students/${studentId}/achievements`).then((r) => r.data.badges);

export const completeOnboarding = (studentId: number): Promise<void> =>
  api.post(`/students/${studentId}/complete_onboarding`).then(() => undefined);

export const fetchCondition = (studentId: number): Promise<Condition> =>
  api.get<Condition>(`/students/${studentId}/condition`).then((r) => r.data);

// ===== 管理（admin） =====
export const fetchAdminMeta = (): Promise<AdminMeta> =>
  api.get<AdminMeta>("/admin/meta").then((r) => r.data);

export const fetchAdminUnits = (): Promise<AdminUnit[]> =>
  api.get<AdminUnit[]>("/admin/units").then((r) => r.data);
export const createAdminUnit = (unit: Partial<AdminUnit>): Promise<AdminUnit> =>
  api.post<AdminUnit>("/admin/units", { unit }).then((r) => r.data);
export const updateAdminUnit = (id: number, unit: Partial<AdminUnit>): Promise<AdminUnit> =>
  api.put<AdminUnit>(`/admin/units/${id}`, { unit }).then((r) => r.data);
export const deleteAdminUnit = (id: number): Promise<void> =>
  api.delete(`/admin/units/${id}`).then(() => undefined);

export const fetchAdminProblems = (unitId: number): Promise<AdminProblem[]> =>
  api.get<AdminProblem[]>("/admin/problems", { params: { unit_id: unitId } }).then((r) => r.data);
export const createAdminProblem = (problem: Partial<AdminProblem>, choices: AdminChoice[]): Promise<AdminProblem> =>
  api.post<AdminProblem>("/admin/problems", { problem, choices }).then((r) => r.data);
export const updateAdminProblem = (id: number, problem: Partial<AdminProblem>, choices: AdminChoice[]): Promise<AdminProblem> =>
  api.put<AdminProblem>(`/admin/problems/${id}`, { problem, choices }).then((r) => r.data);
export const deleteAdminProblem = (id: number): Promise<void> =>
  api.delete(`/admin/problems/${id}`).then(() => undefined);

export const fetchAdminReferenceStats = (): Promise<AdminReferenceStat[]> =>
  api.get<AdminReferenceStat[]>("/admin/reference_stats").then((r) => r.data);
export const createAdminReferenceStat = (reference_stat: Partial<AdminReferenceStat>): Promise<AdminReferenceStat> =>
  api.post<AdminReferenceStat>("/admin/reference_stats", { reference_stat }).then((r) => r.data);
export const updateAdminReferenceStat = (id: number, reference_stat: Partial<AdminReferenceStat>): Promise<AdminReferenceStat> =>
  api.put<AdminReferenceStat>(`/admin/reference_stats/${id}`, { reference_stat }).then((r) => r.data);
export const deleteAdminReferenceStat = (id: number): Promise<void> =>
  api.delete(`/admin/reference_stats/${id}`).then(() => undefined);

export const fetchAdminStudents = (): Promise<AdminStudentSummary[]> =>
  api.get<AdminStudentSummary[]>("/admin/students").then((r) => r.data);
export const deleteAdminStudent = (id: number): Promise<void> =>
  api.delete(`/admin/students/${id}`).then(() => undefined);

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
