import { useEffect, useState } from "react";
import { fetchDailyProblem, submitAnswer } from "../api";
import type { Problem, AnswerResult } from "../types";
import ProblemView from "./ProblemView";

export default function DailyProblemCard({ studentId }: { studentId: number }) {
  const [problem, setProblem] = useState<Problem | null>(null);
  const [answer, setAnswer] = useState("");
  const [feedback, setFeedback] = useState<AnswerResult | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const load = () => {
    setAnswer(""); setFeedback(null);
    fetchDailyProblem(studentId).then(setProblem).catch(() => {});
  };

  useEffect(() => { load(); /* eslint-disable-next-line react-hooks/exhaustive-deps */ }, [studentId]);

  if (!problem) return null;

  const check = async () => {
    if (!answer.trim() || submitting) return;
    setSubmitting(true);
    try {
      setFeedback(await submitAnswer(studentId, problem.id, answer.trim()));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="daily-problem-card">
      <div className="daily-problem-head">
        <span>💡 今日の一問</span>
      </div>

      {feedback ? (
        <div className={`daily-feedback ${feedback.is_correct ? "correct" : "incorrect"}`}>
          <p style={{ fontSize: "1.4rem", marginBottom: "0.25rem" }}>{feedback.is_correct ? "◎" : "✕"}</p>
          <p style={{ fontSize: "0.9rem", marginBottom: "0.75rem" }}>{feedback.explanation}</p>
          <button className="btn-secondary" style={{ padding: "0.4rem 1rem", fontSize: "0.85rem" }} onClick={load}>
            もう一問 →
          </button>
        </div>
      ) : (
        <>
          <p className="daily-question">{problem.question}</p>
          {problem.problem_type === "multiple_choice" ? (
            <ProblemView problem={problem} value={answer} onChange={setAnswer} />
          ) : (
            <input
              type="text"
              className="answer-input"
              value={answer}
              onChange={(e) => setAnswer(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && check()}
              placeholder="答えを入力..."
              style={{ marginBottom: "0.6rem" }}
            />
          )}
          <button className="btn-primary" style={{ width: "100%", padding: "0.55rem" }} onClick={check} disabled={submitting || !answer.trim()}>
            {submitting ? "..." : "答える"}
          </button>
        </>
      )}
    </div>
  );
}
