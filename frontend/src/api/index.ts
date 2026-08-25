import api from "./client";
import type { Grade, Unit, Student, AuthResult, AnswerResult, StudentProgress, StudentStat, ReferenceStat, LearningPlan, ScopeType, ProblemSet, TestResult, TestSubmitResult, Growth, ReviewList, DailyQuota, LessonReadResult, Problem, Condition, AdminMeta, AdminUnit, AdminProblem, AdminChoice, AdminReferenceStat, AdminStudentSummary, AiUsage, AskKind, PersonaKind, AskTeacherResult, Achievements, Child, RankStatus, PromotionExamSet, PromotionExamResult } from "../types";

// stat_type_id は後から足したフィールド。旧バックエンドの窓では返ってこないので
// 既定値（null＝不明）を埋める。不明のときは教科でしぼらず全部見せる側に倒す
export const fetchGrades = (): Promise<Grade[]> =>
  api.get<Grade[]>("/grades").then((r) =>
    r.data.map((g) => ({ ...g, units: (g.units ?? []).map((u) => ({ ...u, stat_type_id: u.stat_type_id ?? null })) }))
  );

export const fetchUnit = (id: number): Promise<Unit> =>
  api.get<Unit>(`/units/${id}`).then((r) => r.data);

export const signup = (name: string, username: string, password: string): Promise<AuthResult> =>
  api.post<AuthResult>("/signup", { name, username, password }).then((r) => r.data);

export const login = (username: string, password: string): Promise<AuthResult> =>
  api.post<AuthResult>("/login", { username, password }).then((r) => r.data);

// guardians / role は後から足したフィールド。旧バックエンドの窓でも落ちないよう既定値を埋める
export const fetchStudent = (id: number): Promise<Student> =>
  api.get<Student>(`/students/${id}`).then((r) => ({
    ...r.data,
    role: r.data.role ?? "student",
    guardians: r.data.guardians ?? [],
  }));

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

// mode="practice" … 練習。同じ問題ばかり出ないよう優先度をつけて選ばれる（問題集）
// mode 未指定     … 範囲全体からランダム（テスト。実力測定なので解ける問題も含める）
// subjectId は範囲とは別軸のしぼり込み。教科が1つしか無いうちは null（送らない）
export const fetchProblemSet = (
  scopeType: ScopeType,
  scopeId: number | null,
  count: number,
  mode?: "practice",
  subjectId?: number | null
): Promise<ProblemSet> =>
  api
    .get<ProblemSet>("/problem_set", {
      params: { scope_type: scopeType, scope_id: scopeId, subject_id: subjectId ?? undefined, count, mode },
    })
    .then((r) => ({ ...r.data, subject_id: r.data.subject_id ?? null }));

export const submitTest = (
  studentId: number,
  scopeType: ScopeType,
  scopeId: number | null,
  answers: { problem_id: number; submitted_answer: string }[],
  subjectId?: number | null
): Promise<TestSubmitResult> =>
  api
    .post<TestSubmitResult>(`/students/${studentId}/test_results`, {
      scope_type: scopeType,
      scope_id: scopeId,
      subject_id: subjectId ?? null,
      answers,
    })
    .then((r) => ({ ...r.data, subject_id: r.data.subject_id ?? null }));

export const fetchTestResults = (studentId: number): Promise<TestResult[]> =>
  api.get<TestResult[]>(`/students/${studentId}/test_results`).then((r) =>
    r.data.map((t) => ({ ...t, subject_id: t.subject_id ?? null }))
  );

export const fetchGrowth = (studentId: number): Promise<Growth> =>
  api.get<Growth>(`/students/${studentId}/growth`).then((r) => r.data);

export const fetchReviewList = (studentId: number): Promise<ReviewList> =>
  api.get<ReviewList>(`/students/${studentId}/review`).then((r) => r.data);

// quota_streak は後から足したフィールド。旧バックエンドから返ってこない窓があるので既定値を埋める
export const fetchDailyQuota = (studentId: number): Promise<DailyQuota> =>
  api.get<DailyQuota>(`/students/${studentId}/quota`).then((r) => ({
    ...r.data,
    quota_streak: r.data.quota_streak ?? 0,
  }));

export const fetchLessonReads = (studentId: number): Promise<number[]> =>
  api.get<{ unit_ids: number[] }>(`/students/${studentId}/lesson_reads`).then((r) => r.data.unit_ids);

export const markLessonRead = (studentId: number, unitId: number): Promise<LessonReadResult> =>
  api.post<LessonReadResult>(`/students/${studentId}/lesson_reads`, { unit_id: unitId }).then((r) => r.data);

export const fetchDailyProblem = (studentId: number): Promise<Problem | null> =>
  api.get<{ problem: Problem | null }>(`/students/${studentId}/daily_problem`).then((r) => r.data.problem);

// 応答の形が欠けていても画面を落とさないよう、ここで既定値を埋めてから返す。
// フロント(Vercel)とバックエンド(Railway)はデプロイ時間が違うので、新しいフロントが
// 一時的に古いバックエンド（titles / newly_earned を返さない）を叩くことがある。
export const fetchAchievements = (studentId: number): Promise<Achievements> =>
  api.get<Partial<Achievements>>(`/students/${studentId}/achievements`).then((r) => ({
    badges: r.data.badges ?? [],
    newly_earned: r.data.newly_earned ?? [],
    title_key: r.data.title_key ?? null,
    title: r.data.title ?? null,
    titles: r.data.titles ?? [],
  }));

export const updateTitle = (studentId: number, titleKey: string | null) =>
  api
    .put<{ title_key: string | null; title: string | null }>(`/students/${studentId}/title`, {
      title_key: titleKey,
    })
    .then((r) => r.data);

// ===== 総合ランクと昇格試験 =====

export const fetchRankStatus = (studentId: number): Promise<RankStatus> =>
  api.get<RankStatus>(`/students/${studentId}/rank`).then((r) => r.data);

export const fetchPromotionExam = (studentId: number): Promise<PromotionExamSet> =>
  api.get<PromotionExamSet>(`/students/${studentId}/promotion_exam`).then((r) => r.data);

export const submitPromotionExam = (
  studentId: number,
  answers: { problem_id: number; submitted_answer: string }[]
): Promise<PromotionExamResult> =>
  api
    .post<PromotionExamResult>(`/students/${studentId}/promotion_exam`, { answers })
    .then((r) => r.data);

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

// ===== この人に聞く（職業ペルソナへの相談） =====
// 「先生に聞く」とは回数の枠が別なので、専用のエンドポイントを叩く
export const fetchPersonaUsage = (studentId: number): Promise<AiUsage> =>
  api.get<AiUsage>(`/students/${studentId}/persona_usage`).then((r) => r.data);

export const askPersona = (
  studentId: number,
  characterKey: string,
  kind: PersonaKind,
  question?: string
): Promise<AskTeacherResult> =>
  api
    .post<AskTeacherResult>(`/students/${studentId}/ask_persona`, {
      character_key: characterKey,
      kind,
      question,
    })
    .then((r) => r.data);

// ===== 保護者 =====
// role は後から足したフィールド。旧バックエンドから返ってこない窓があるので既定値を埋める
export const fetchChildren = (): Promise<Child[]> =>
  api.get<Child[]>("/children").then((r) => r.data ?? []);

export const createAdminAccount = (name: string, username: string, role: "parent" | "student") =>
  api.post<{ id: number; name: string; username: string; role: string; password: string }>(
    "/admin/students", { name, username, role }
  ).then((r) => r.data);

export const linkGuardianship = (guardianId: number, studentId: number) =>
  api.post<{ id: number; name: string }>(`/admin/students/${guardianId}/guardianships`, {
    student_id: studentId,
  }).then((r) => r.data);

export const unlinkGuardianship = (guardianId: number, studentId: number): Promise<void> =>
  api.delete(`/admin/students/${guardianId}/guardianships/${studentId}`).then(() => undefined);

export const fetchAdminReferenceStats = (): Promise<AdminReferenceStat[]> =>
  api.get<AdminReferenceStat[]>("/admin/reference_stats").then((r) => r.data);
export const createAdminReferenceStat = (reference_stat: Partial<AdminReferenceStat>): Promise<AdminReferenceStat> =>
  api.post<AdminReferenceStat>("/admin/reference_stats", { reference_stat }).then((r) => r.data);
export const updateAdminReferenceStat = (id: number, reference_stat: Partial<AdminReferenceStat>): Promise<AdminReferenceStat> =>
  api.put<AdminReferenceStat>(`/admin/reference_stats/${id}`, { reference_stat }).then((r) => r.data);
export const deleteAdminReferenceStat = (id: number): Promise<void> =>
  api.delete(`/admin/reference_stats/${id}`).then(() => undefined);

export const fetchAdminStudents = (): Promise<AdminStudentSummary[]> =>
  api.get<AdminStudentSummary[]>("/admin/students").then((r) =>
    (r.data ?? []).map((s) => ({
      ...s,
      role: s.role ?? "student",
      children: s.children ?? [],
      guardians: s.guardians ?? [],
    }))
  );
export const deleteAdminStudent = (id: number): Promise<void> =>
  api.delete(`/admin/students/${id}`).then(() => undefined);
// パスワードを忘れた生徒の救済。新しいパスワードはこの応答でしか受け取れない
export const resetStudentPassword = (id: number): Promise<{ password: string }> =>
  api.post<{ password: string }>(`/admin/students/${id}/reset_password`).then((r) => r.data);

// 生徒が自分でパスワードを変える。変更でトークンが失効するので新しいトークンが返る
export const changePassword = (
  studentId: number,
  currentPassword: string,
  newPassword: string
): Promise<{ token: string }> =>
  api
    .put<{ token: string }>(`/students/${studentId}/password`, {
      current_password: currentPassword,
      new_password: newPassword,
    })
    .then((r) => r.data);

export const fetchAiUsage = (studentId: number): Promise<AiUsage> =>
  api.get<AiUsage>(`/students/${studentId}/ai_usage`).then((r) => r.data);

export const askTeacher = (
  studentId: number,
  problemId: number,
  kind: AskKind,
  question?: string
): Promise<AskTeacherResult> =>
  api
    .post<AskTeacherResult>(`/students/${studentId}/ask_teacher`, {
      problem_id: problemId,
      kind,
      question,
    })
    .then((r) => r.data);

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
    // solution は後から足したフィールド。旧バックエンドから返ってこない窓があるので既定値を埋める
    .then((r) => ({ ...r.data, solution: r.data.solution ?? null }));
