import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { fetchGrades, fetchStudentStats, fetchProblemSet, submitTest } from "../api";
import type { Grade, StudentStat, Problem, ScopeType, TestSubmitResult } from "../types";
import ProblemView from "../components/ProblemView";
import { playFinish } from "../sound";

const COUNTS = [5, 10, 20];
const TIME_LIMITS = [
  { m: 0, label: "なし" },
  { m: 5, label: "5分" },
  { m: 10, label: "10分" },
];
type Phase = "setup" | "running" | "result";

type TargetOption = { id: number; label: string };

const RANK_COLOR: Record<string, string> = { S: "#d69e2e", A: "#38a169", B: "#4c51bf", C: "#718096" };

export default function TestPage() {
  const navigate = useNavigate();
  const studentId = Number(localStorage.getItem("studentId"));

  const [grades, setGrades] = useState<Grade[]>([]);
  const [stats, setStats] = useState<StudentStat[]>([]);
  const [loading, setLoading] = useState(true);

  const [scopeType, setScopeType] = useState<ScopeType>("grade");
  const [targetId, setTargetId] = useState<number | null>(null);
  const [count, setCount] = useState(10);
  const [timeLimit, setTimeLimit] = useState(0); // 分（0=なし）
  const [remaining, setRemaining] = useState(0); // 秒
  const [phase, setPhase] = useState<Phase>("setup");

  const [problems, setProblems] = useState<Problem[]>([]);
  const [idx, setIdx] = useState(0);
  const [answers, setAnswers] = useState<string[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [result, setResult] = useState<TestSubmitResult | null>(null);

  useEffect(() => {
    if (!studentId) { navigate("/"); return; }
    Promise.all([fetchGrades(), fetchStudentStats(studentId)])
      .then(([g, s]) => {
        setGrades(g);
        setStats(s);
        setTargetId(g[0]?.id ?? null);
      })
      .finally(() => setLoading(false));
  }, [studentId, navigate]);

  // テストタイプごとの選択肢
  const targets: TargetOption[] =
    scopeType === "grade"
      ? grades.map((g) => ({ id: g.id, label: g.name }))
      : scopeType === "stat_type"
      ? stats.map((s) => ({ id: s.stat_type_id, label: s.name }))
      : grades.flatMap((g) => (g.units || []).map((u) => ({ id: u.id, label: `${g.name}｜${u.title}` })));

  const pickType = (t: ScopeType) => {
    setScopeType(t);
    const first =
      t === "grade" ? grades[0]?.id
      : t === "stat_type" ? stats[0]?.stat_type_id
      : grades.flatMap((g) => g.units || [])[0]?.id;
    setTargetId(first ?? null);
  };

  const start = async () => {
    if (!targetId) return;
    setLoading(true);
    try {
      const set = await fetchProblemSet(scopeType, targetId, count);
      setProblems(set.problems);
      setAnswers(new Array(set.problems.length).fill(""));
      setIdx(0);
      if (timeLimit > 0) setRemaining(timeLimit * 60);
      setPhase("running");
    } finally {
      setLoading(false);
    }
  };

  const setAnswer = (v: string) => {
    setAnswers((prev) => { const n = [...prev]; n[idx] = v; return n; });
  };

  const submit = async () => {
    if (submitting) return;
    setSubmitting(true);
    try {
      const payload = problems.map((p, i) => ({ problem_id: p.id, submitted_answer: answers[i] || "" }));
      const res = await submitTest(studentId, scopeType, targetId, payload);
      playFinish();
      setResult(res);
      setPhase("result");
    } finally {
      setSubmitting(false);
    }
  };

  // 制限時間のカウントダウン（0で自動提出）
  useEffect(() => {
    if (phase !== "running" || timeLimit === 0) return;
    if (remaining <= 0) { submit(); return; }
    const t = setTimeout(() => setRemaining((r) => r - 1), 1000);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [phase, remaining, timeLimit]);

  const mmss = (s: number) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;

  if (loading) return <div className="loading">読み込み中...</div>;

  // ===== 設定 =====
  if (phase === "setup") {
    const typeLabels: { key: ScopeType; label: string }[] = [
      { key: "grade", label: "学年まとめ" },
      { key: "stat_type", label: "ステータス別" },
      { key: "unit", label: "単元別" },
    ];
    return (
      <div className="page">
        <header className="page-header">
          <button className="btn-back" onClick={() => navigate("/home")}>← ホーム</button>
        </header>
        <h2 style={{ fontSize: "1.4rem", fontWeight: 700, marginBottom: "0.25rem" }}>テスト</h2>
        <p style={{ color: "#718096", fontSize: "0.9rem", marginBottom: "1.5rem" }}>
          途中で答え合わせはせず、最後にまとめて採点します
        </p>

        <div className="setup-card">
          <label className="setup-label">テストの種類</label>
          <div className="chip-row">
            {typeLabels.map((t) => (
              <button key={t.key} className={`chip ${scopeType === t.key ? "chip-on" : ""}`} onClick={() => pickType(t.key)}>
                {t.label}
              </button>
            ))}
          </div>

          <label className="setup-label" style={{ marginTop: "1.25rem" }}>範囲</label>
          <div className="chip-row" style={{ maxHeight: 180, overflowY: "auto" }}>
            {targets.map((t) => (
              <button key={t.id} className={`chip ${targetId === t.id ? "chip-on" : ""}`} onClick={() => setTargetId(t.id)}>
                {t.label}
              </button>
            ))}
          </div>

          <label className="setup-label" style={{ marginTop: "1.25rem" }}>問題数</label>
          <div className="chip-row">
            {COUNTS.map((c) => (
              <button key={c} className={`chip ${count === c ? "chip-on" : ""}`} onClick={() => setCount(c)}>
                {c}問
              </button>
            ))}
          </div>

          <label className="setup-label" style={{ marginTop: "1.25rem" }}>制限時間</label>
          <div className="chip-row">
            {TIME_LIMITS.map((t) => (
              <button key={t.m} className={`chip ${timeLimit === t.m ? "chip-on" : ""}`} onClick={() => setTimeLimit(t.m)}>
                {t.label}
              </button>
            ))}
          </div>

          <button className="btn-primary" style={{ marginTop: "1.5rem", width: "100%" }} onClick={start} disabled={!targetId}>
            テストをはじめる
          </button>
        </div>
      </div>
    );
  }

  // ===== 結果 =====
  if (phase === "result" && result) {
    const rankColor = RANK_COLOR[result.rank] ?? "#4c51bf";
    const diff = result.previous_score != null ? result.score_percent - result.previous_score : null;
    return (
      <div className="page">
        <div className="result-summary">
          <p className="unit-name">{result.scope_label}</p>
          <div className="rank-badge" style={{ color: rankColor, borderColor: rankColor }}>{result.rank}</div>
          <div className="score-display" style={{ marginTop: "0.5rem" }}>
            <span className="score-num">{result.score_percent}</span>
            <span className="score-label">点</span>
          </div>
          <p className="accuracy">{result.correct_count} / {result.total_questions} 問正解</p>

          {result.is_best && (
            <p style={{ fontSize: "0.95rem", color: "#d69e2e", fontWeight: 700, marginBottom: "0.5rem" }}>
              ★ 自己ベスト更新！
            </p>
          )}
          {diff != null && (
            <p style={{ fontSize: "0.9rem", color: diff >= 0 ? "#38a169" : "#e53e3e", marginBottom: "0.5rem" }}>
              前回より {diff >= 0 ? "+" : ""}{diff}点（前回 {result.previous_score}点）
            </p>
          )}
          {result.bonus_points > 0 && (
            <p style={{ fontSize: "0.95rem", color: "#d69e2e", fontWeight: 700, marginBottom: "1rem" }}>
              🎉 高得点ボーナス +{result.bonus_points}pt！
            </p>
          )}

          <div className="result-actions">
            <button className="btn-primary" onClick={() => { setResult(null); setPhase("setup"); }}>もう一度</button>
            <button className="btn-secondary" onClick={() => navigate("/test-history")}>履歴を見る</button>
            <button className="btn-secondary" onClick={() => navigate("/home")}>ホームへ</button>
          </div>
        </div>
      </div>
    );
  }

  // ===== テスト中（フィードバックなし） =====
  const problem = problems[idx];
  const isLast = idx + 1 >= problems.length;
  return (
    <div className="page">
      <header className="practice-header">
        <button className="btn-back" onClick={() => navigate("/home")}>← ホーム</button>
        <div className="unit-info">
          <span className="unit-title-small">テスト</span>
          <span className="progress-indicator">{idx + 1} / {problems.length}問</span>
        </div>
        {timeLimit > 0 && (
          <span className="test-timer" style={{ color: remaining <= 30 ? "#e53e3e" : "#4a5568" }}>
            ⏱ {mmss(remaining)}
          </span>
        )}
      </header>

      <div className="progress-bar-wrap">
        <div className="progress-bar-fill" style={{ width: `${((idx + 1) / problems.length) * 100}%` }} />
      </div>

      <div className="problem-card">
        <ProblemView problem={problem} value={answers[idx]} onChange={setAnswer} onEnter={() => !isLast && setIdx((i) => i + 1)} />
        <div className="action-row">
          {idx > 0 && (
            <button className="btn-secondary" onClick={() => setIdx((i) => i - 1)}>← 前へ</button>
          )}
          {isLast ? (
            <button className="btn-primary" onClick={submit} disabled={submitting}>
              {submitting ? "採点中..." : "提出して採点"}
            </button>
          ) : (
            <button className="btn-primary" onClick={() => setIdx((i) => i + 1)}>次へ →</button>
          )}
        </div>
      </div>

      <div className="session-score">答えは最後にまとめて採点されます</div>
    </div>
  );
}
