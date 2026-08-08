import { useEffect, useState } from "react";
import { useNavigate } from "react-router";
import { fetchPromotionExam, submitPromotionExam } from "../api";
import type { Problem, PromotionExamSet, PromotionExamResult } from "../types";
import ProblemView from "../components/ProblemView";
import MathText from "../components/MathText";
import AnswerInput from "../components/AnswerInput";
import ScratchPad from "../components/ScratchPad";
import { playFinish } from "../sound";

// 昇格試験。通常のテストと違い、範囲・問題数・合格ラインは固定で選べない。
// 出題は「その子が学んだ単元」から（PromotionExam サービス側で解決している）。
// 先生に聞く導線は出さない（実力を測る場なので、テスト画面と同じ扱い）。
type Phase = "intro" | "running" | "result";

export default function PromotionExamPage() {
  const navigate = useNavigate();
  const studentId = Number(localStorage.getItem("studentId"));

  const [phase, setPhase] = useState<Phase>("intro");
  const [exam, setExam] = useState<PromotionExamSet | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const [idx, setIdx] = useState(0);
  const [answers, setAnswers] = useState<Record<number, string>>({});
  const [submitting, setSubmitting] = useState(false);
  const [result, setResult] = useState<PromotionExamResult | null>(null);

  useEffect(() => {
    if (!studentId) { navigate("/"); return; }
    fetchPromotionExam(studentId)
      .then(setExam)
      .catch((e) => setError(e?.response?.data?.error || "いまは昇格試験を受けられません。"))
      .finally(() => setLoading(false));
  }, [studentId, navigate]);

  const problems: Problem[] = exam?.problems ?? [];
  const current = problems[idx];
  const answered = Object.values(answers).filter((a) => a.trim()).length;

  const setAnswer = (value: string) => {
    if (!current) return;
    setAnswers((prev) => ({ ...prev, [current.id]: value }));
  };

  const submit = async () => {
    if (submitting) return;
    setSubmitting(true);
    try {
      const payload = problems.map((p) => ({
        problem_id: p.id,
        submitted_answer: (answers[p.id] ?? "").trim(),
      }));
      const res = await submitPromotionExam(studentId, payload);
      playFinish();
      setResult(res);
      setPhase("result");
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } } };
      setError(err?.response?.data?.error || "提出できませんでした。もう一度ためしてね。");
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return <div className="loading">読み込み中...</div>;

  if (error && phase !== "result") {
    return (
      <div className="page">
        <div className="result-summary">
          <h2>昇格試験</h2>
          <p className="unit-name">{error}</p>
          <div className="result-actions">
            <button className="btn-primary" onClick={() => navigate("/home")}>ホームへ</button>
          </div>
        </div>
      </div>
    );
  }

  // ===== 結果 =====
  if (phase === "result" && result) {
    const next = result.status;
    return (
      <div className="page">
        <div className={`exam-result ${result.passed ? "passed" : "failed"}`}>
          <p className="exam-result-mark">{result.passed ? "🎉" : "💪"}</p>
          <h2>{result.passed ? "合格！" : "また ちょうせんしよう"}</h2>
          <p className="exam-result-score">
            {result.correct_count} / {result.total_questions} 問正解（{result.score_percent}%）
          </p>

          {result.passed ? (
            <p className="exam-result-note">
              <strong>{next.current_rank.name}</strong> に昇格したよ！
            </p>
          ) : (
            <p className="exam-result-note">
              もう一度受けるには あと <strong>{next.retry_points_needed}pt</strong>。
              問題を解いてポイントをためよう。
            </p>
          )}

          <div className="result-actions">
            <button className="btn-primary" onClick={() => navigate("/home")}>ホームへ</button>
            {!result.passed && (
              <button className="btn-secondary" onClick={() => navigate("/plan")}>今日のプランへ</button>
            )}
          </div>
        </div>
      </div>
    );
  }

  // ===== 説明 =====
  if (phase === "intro" && exam) {
    return (
      <div className="page">
        <header className="page-header">
          <button className="btn-back" onClick={() => navigate("/home")}>← ホーム</button>
        </header>

        <div className="exam-intro">
          <p className="exam-intro-emoji">⚔️</p>
          <h2>{exam.rank.name} 昇格試験</h2>
          <ul className="exam-intro-list">
            <li>出題は <strong>{exam.scope_label}</strong> から</li>
            <li>ぜんぶで <strong>{exam.problems.length}問</strong></li>
            <li><strong>{exam.pass_percent}%以上</strong>で合格</li>
            <li>制限時間はなし。じっくり考えてね</li>
          </ul>
          <p className="exam-intro-note">
            落ちてもポイントは減りません。もう一度受けるには少しポイントをためてね。
          </p>
          <button className="btn-primary" style={{ width: "100%", padding: "0.7rem" }} onClick={() => setPhase("running")}>
            はじめる
          </button>
        </div>
      </div>
    );
  }

  // ===== 出題 =====
  if (!current) return <div className="loading">読み込み中...</div>;

  const isLast = idx + 1 >= problems.length;

  return (
    <div className="page">
      <header className="page-header">
        <span className="exam-progress">⚔️ {exam?.rank.name} 昇格試験　{idx + 1} / {problems.length}</span>
      </header>

      <div className="exam-bar">
        <div className="exam-bar-fill" style={{ width: `${((idx + 1) / problems.length) * 100}%` }} />
      </div>

      <p className="daily-question" style={{ marginTop: "1rem" }}>
        <MathText>{current.question}</MathText>
      </p>

      <ScratchPad key={current.id} />

      {current.problem_type === "multiple_choice" ? (
        <ProblemView problem={current} value={answers[current.id] ?? ""} onChange={setAnswer} />
      ) : (
        <AnswerInput value={answers[current.id] ?? ""} onChange={setAnswer} />
      )}

      <div className="exam-nav">
        <button className="btn-secondary" disabled={idx === 0} onClick={() => setIdx((i) => i - 1)}>
          ← まえ
        </button>
        {isLast ? (
          <button className="btn-primary" onClick={submit} disabled={submitting}>
            {submitting ? "採点中..." : `提出する（${answered}/${problems.length}問）`}
          </button>
        ) : (
          <button className="btn-primary" onClick={() => setIdx((i) => i + 1)}>つぎ →</button>
        )}
      </div>
    </div>
  );
}
