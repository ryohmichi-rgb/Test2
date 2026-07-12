import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { fetchReviewList, submitAnswer } from "../api";
import type { Problem, AnswerResult } from "../types";
import ProblemView from "../components/ProblemView";

export default function ReviewPage() {
  const navigate = useNavigate();
  const studentId = Number(localStorage.getItem("studentId"));

  const [problems, setProblems] = useState<Problem[]>([]);
  const [loading, setLoading] = useState(true);
  const [idx, setIdx] = useState(0);
  const [answer, setAnswer] = useState("");
  const [feedback, setFeedback] = useState<AnswerResult | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [fixed, setFixed] = useState(0);
  const [done, setDone] = useState(false);

  useEffect(() => {
    if (!studentId) { navigate("/"); return; }
    fetchReviewList(studentId).then((r) => setProblems(r.problems)).finally(() => setLoading(false));
  }, [studentId, navigate]);

  const check = async () => {
    if (!answer.trim() || submitting) return;
    setSubmitting(true);
    try {
      const res = await submitAnswer(studentId, problems[idx].id, answer.trim());
      setFeedback(res);
      if (res.is_correct) setFixed((f) => f + 1);
    } finally {
      setSubmitting(false);
    }
  };

  const next = () => {
    if (idx + 1 >= problems.length) { setDone(true); return; }
    setIdx((i) => i + 1);
    setAnswer(""); setFeedback(null);
  };

  if (loading) return <div className="loading">読み込み中...</div>;

  if (problems.length === 0) {
    return (
      <div className="page">
        <div className="result-summary">
          <h2>復習はありません 🎉</h2>
          <p className="unit-name">間違えたままの問題はありません</p>
          <div className="result-actions">
            <button className="btn-primary" onClick={() => navigate("/home")}>ホームへ</button>
          </div>
        </div>
      </div>
    );
  }

  if (done) {
    return (
      <div className="page">
        <div className="result-summary">
          <h2>復習おつかれさま！</h2>
          <div className="score-display">
            <span className="score-num">{fixed}</span>
            <span className="score-sep"> / </span>
            <span className="score-total">{problems.length}</span>
            <span className="score-label"> 問クリア</span>
          </div>
          <p className="accuracy">正解した問題は復習リストから外れます</p>
          <div className="result-actions">
            <button className="btn-primary" onClick={() => navigate("/home")}>ホームへ</button>
          </div>
        </div>
      </div>
    );
  }

  const problem = problems[idx];
  return (
    <div className="page">
      <header className="practice-header">
        <button className="btn-back" onClick={() => navigate("/home")}>← ホーム</button>
        <div className="unit-info">
          <span className="unit-title-small">復習</span>
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
    </div>
  );
}
