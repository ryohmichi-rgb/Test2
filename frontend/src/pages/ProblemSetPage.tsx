import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { fetchGrades, fetchProblemSet, submitAnswer } from "../api";
import type { Grade, Problem, AnswerResult } from "../types";
import ProblemView from "../components/ProblemView";
import { playCorrect, playIncorrect } from "../sound";

const COUNTS = [5, 10, 20];
type Phase = "setup" | "running" | "done";

type Saved = { problems: Problem[]; idx: number; correctTotal: number };

export default function ProblemSetPage() {
  const navigate = useNavigate();
  const studentId = Number(localStorage.getItem("studentId"));
  const STORAGE_KEY = `problemset_${studentId}`;

  const [grades, setGrades] = useState<Grade[]>([]);
  const [gradeId, setGradeId] = useState<number | null>(null);
  const [count, setCount] = useState(10);
  const [phase, setPhase] = useState<Phase>("setup");
  const [loading, setLoading] = useState(true);
  const [saved, setSaved] = useState<Saved | null>(null);

  const [problems, setProblems] = useState<Problem[]>([]);
  const [idx, setIdx] = useState(0);
  const [answer, setAnswer] = useState("");
  const [feedback, setFeedback] = useState<AnswerResult | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [correctTotal, setCorrectTotal] = useState(0);

  useEffect(() => {
    if (!studentId) { navigate("/"); return; }
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) setSaved(JSON.parse(raw));
    } catch { /* ignore */ }
    fetchGrades().then((g) => {
      setGrades(g);
      setGradeId(g[0]?.id ?? null);
    }).finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [studentId, navigate]);

  const persist = (p: Problem[], i: number, c: number) => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ problems: p, idx: i, correctTotal: c }));
  };
  const clearSaved = () => { localStorage.removeItem(STORAGE_KEY); setSaved(null); };

  const resume = () => {
    if (!saved) return;
    setProblems(saved.problems);
    setIdx(saved.idx);
    setCorrectTotal(saved.correctTotal);
    setAnswer(""); setFeedback(null);
    setPhase("running");
  };

  const start = async () => {
    if (!gradeId) return;
    setLoading(true);
    try {
      const set = await fetchProblemSet("grade", gradeId, count);
      setProblems(set.problems);
      setIdx(0); setAnswer(""); setFeedback(null); setCorrectTotal(0);
      persist(set.problems, 0, 0);
      setSaved(null);
      setPhase("running");
    } finally {
      setLoading(false);
    }
  };

  const check = async () => {
    if (!answer.trim() || submitting) return;
    setSubmitting(true);
    try {
      const res = await submitAnswer(studentId, problems[idx].id, answer.trim());
      (res.is_correct ? playCorrect : playIncorrect)();
      setFeedback(res);
      if (res.is_correct) setCorrectTotal((c) => c + 1);
    } finally {
      setSubmitting(false);
    }
  };

  const next = () => {
    if (idx + 1 >= problems.length) { clearSaved(); setPhase("done"); return; }
    const ni = idx + 1;
    setIdx(ni);
    setAnswer(""); setFeedback(null);
    persist(problems, ni, correctTotal);
  };

  if (loading) return <div className="loading">読み込み中...</div>;

  // ===== 設定 =====
  if (phase === "setup") {
    return (
      <div className="page">
        <header className="page-header">
          <button className="btn-back" onClick={() => navigate("/home")}>← ホーム</button>
        </header>
        <h2 style={{ fontSize: "1.4rem", fontWeight: 700, marginBottom: "0.25rem" }}>問題集</h2>
        <p style={{ color: "#718096", fontSize: "0.9rem", marginBottom: "1.5rem" }}>
          学年の範囲をまとめて練習します（1問ずつ答え合わせ）
        </p>

        {saved && saved.problems.length > 0 && (
          <div className="resume-banner">
            <div>
              <p style={{ fontWeight: 700, fontSize: "0.95rem" }}>やりかけの問題集があります</p>
              <p style={{ fontSize: "0.8rem", color: "#718096" }}>
                {saved.idx + 1} / {saved.problems.length}問目から
              </p>
            </div>
            <div style={{ display: "flex", gap: "0.5rem" }}>
              <button className="btn-primary" style={{ padding: "0.45rem 1rem", fontSize: "0.88rem" }} onClick={resume}>続きから</button>
              <button className="btn-hint" style={{ fontSize: "0.85rem" }} onClick={clearSaved}>やめる</button>
            </div>
          </div>
        )}

        <div className="setup-card">
          <label className="setup-label">学年</label>
          <div className="chip-row">
            {grades.map((g) => (
              <button key={g.id} className={`chip ${gradeId === g.id ? "chip-on" : ""}`} onClick={() => setGradeId(g.id)}>
                {g.name}
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

          <button className="btn-primary" style={{ marginTop: "1.5rem", width: "100%" }} onClick={start} disabled={!gradeId}>
            はじめる
          </button>
        </div>
      </div>
    );
  }

  // ===== 完了サマリー =====
  if (phase === "done") {
    const pct = Math.round((correctTotal / problems.length) * 100);
    return (
      <div className="page">
        <div className="result-summary">
          <h2>おつかれさま！</h2>
          <p className="unit-name">問題集</p>
          <div className="score-display">
            <span className="score-num">{correctTotal}</span>
            <span className="score-sep"> / </span>
            <span className="score-total">{problems.length}</span>
            <span className="score-label"> 問正解</span>
          </div>
          <p className="accuracy">正解率: {pct}%</p>
          <div className="result-actions">
            <button className="btn-primary" onClick={() => setPhase("setup")}>もう一度</button>
            <button className="btn-secondary" onClick={() => navigate("/home")}>ホームへ</button>
          </div>
        </div>
      </div>
    );
  }

  // ===== 演習中 =====
  const problem = problems[idx];
  return (
    <div className="page">
      <header className="practice-header">
        <button className="btn-back" onClick={() => navigate("/home")}>← ホーム</button>
        <div className="unit-info">
          <span className="unit-title-small">問題集</span>
          <span className="progress-indicator">{idx + 1} / {problems.length}問</span>
        </div>
      </header>

      <div className="progress-bar-wrap">
        <div className="progress-bar-fill" style={{ width: `${(idx / problems.length) * 100}%` }} />
      </div>

      <div className="problem-card">
        {feedback ? (
          <>
            <ProblemView problem={problem} value={answer} onChange={() => {}} disabled />
            <div className={`answer-feedback ${feedback.is_correct ? "correct" : "incorrect"}`} style={{ marginTop: "1rem" }}>
              <p className="feedback-emoji">{feedback.is_correct ? "◎" : "✕"}</p>
              <p className="feedback-text">{feedback.explanation}</p>
              <button className="btn-primary" onClick={next}>
                {idx + 1 < problems.length ? "次の問題へ →" : "結果を見る"}
              </button>
            </div>
          </>
        ) : (
          <>
            <ProblemView problem={problem} value={answer} onChange={setAnswer} onEnter={check} />
            <div className="action-row">
              <button className="btn-primary" onClick={check} disabled={submitting || !answer.trim()}>
                {submitting ? "..." : "答える"}
              </button>
            </div>
          </>
        )}
      </div>

      <div className="session-score">今回: {idx}問中 {correctTotal}問正解</div>
    </div>
  );
}
