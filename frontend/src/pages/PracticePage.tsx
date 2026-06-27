import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { fetchUnit, submitAnswer } from "../api";
import type { Unit, Problem, AnswerResult } from "../types";

type ProblemState = {
  answered: boolean;
  result: AnswerResult | null;
  userAnswer: string;
};

export default function PracticePage() {
  const { unitId } = useParams<{ unitId: string }>();
  const navigate = useNavigate();
  const studentId = Number(localStorage.getItem("studentId"));

  const [unit, setUnit] = useState<Unit | null>(null);
  const [loading, setLoading] = useState(true);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [states, setStates] = useState<ProblemState[]>([]);
  const [input, setInput] = useState("");
  const [selectedChoice, setSelectedChoice] = useState<string>("");
  const [showHint, setShowHint] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!studentId) {
      navigate("/");
      return;
    }
    fetchUnit(Number(unitId)).then((u) => {
      setUnit(u);
      setStates((u.problems || []).map(() => ({ answered: false, result: null, userAnswer: "" })));
      setLoading(false);
    });
  }, [unitId, navigate, studentId]);

  if (loading || !unit) return <div className="loading">読み込み中...</div>;

  const problems = unit.problems || [];
  const current: Problem = problems[currentIndex];
  const currentState = states[currentIndex];
  const isMultipleChoice = current?.problem_type === "multiple_choice";
  const totalAnswered = states.filter((s) => s.answered).length;
  const totalCorrect = states.filter((s) => s.result?.is_correct).length;

  const handleSubmit = async () => {
    const answer = isMultipleChoice ? selectedChoice : input.trim();
    if (!answer || submitting) return;
    setSubmitting(true);
    try {
      const result = await submitAnswer(studentId, current.id, answer);
      const newStates = [...states];
      newStates[currentIndex] = { answered: true, result, userAnswer: answer };
      setStates(newStates);
    } finally {
      setSubmitting(false);
    }
  };

  const handleNext = () => {
    setInput("");
    setSelectedChoice("");
    setShowHint(false);
    setCurrentIndex((i) => i + 1);
  };

  const allDone = currentIndex >= problems.length;

  if (allDone) {
    return (
      <div className="page">
        <div className="result-summary">
          <h2>単元完了！</h2>
          <p className="unit-name">{unit.title}</p>
          <div className="score-display">
            <span className="score-num">{totalCorrect}</span>
            <span className="score-sep"> / </span>
            <span className="score-total">{problems.length}</span>
            <span className="score-label"> 問正解</span>
          </div>
          <p className="accuracy">正解率: {Math.round((totalCorrect / problems.length) * 100)}%</p>
          <div className="result-actions">
            <button className="btn-primary" onClick={() => navigate("/grades")}>
              単元一覧に戻る
            </button>
            <button
              className="btn-secondary"
              onClick={() => navigate(`/progress/${studentId}`)}
            >
              進捗を見る
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="page">
      <header className="practice-header">
        <button className="btn-back" onClick={() => navigate("/grades")}>
          ← 戻る
        </button>
        <div className="unit-info">
          <span className="unit-title-small">{unit.title}</span>
          <span className="progress-indicator">
            {currentIndex + 1} / {problems.length}問
          </span>
        </div>
      </header>

      <div className="progress-bar-wrap">
        <div
          className="progress-bar-fill"
          style={{ width: `${(currentIndex / problems.length) * 100}%` }}
        />
      </div>

      <div className="problem-card">
        <div className="difficulty-stars">
          {"★".repeat(current.difficulty)}{"☆".repeat(5 - current.difficulty)}
        </div>

        <p className="problem-question">{current.question}</p>

        {currentState.answered ? (
          <div className={`answer-feedback ${currentState.result?.is_correct ? "correct" : "incorrect"}`}>
            <p className="feedback-emoji">{currentState.result?.is_correct ? "◎" : "✕"}</p>
            <p className="feedback-text">{currentState.result?.explanation}</p>
            <button className="btn-primary" onClick={handleNext}>
              {currentIndex + 1 < problems.length ? "次の問題へ →" : "結果を見る"}
            </button>
          </div>
        ) : (
          <div className="answer-area">
            {isMultipleChoice ? (
              <div className="choices-grid">
                {current.choices?.map((choice) => (
                  <button
                    key={choice.id}
                    className={`choice-btn ${selectedChoice === choice.text ? "selected" : ""}`}
                    onClick={() => setSelectedChoice(choice.text)}
                  >
                    {choice.text}
                  </button>
                ))}
              </div>
            ) : (
              <input
                type="text"
                className="answer-input"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleSubmit()}
                placeholder="答えを入力..."
                autoFocus
              />
            )}

            <div className="action-row">
              <button
                className="btn-hint"
                onClick={() => setShowHint((v) => !v)}
              >
                {showHint ? "ヒントを隠す" : "ヒントを見る"}
              </button>
              <button
                className="btn-primary"
                onClick={handleSubmit}
                disabled={submitting || (isMultipleChoice ? !selectedChoice : !input.trim())}
              >
                {submitting ? "..." : "答える"}
              </button>
            </div>

            {showHint && current.hint && (
              <div className="hint-box">
                <span className="hint-label">ヒント</span>
                <p>{current.hint}</p>
              </div>
            )}
          </div>
        )}
      </div>

      <div className="session-score">
        今回: {totalAnswered}問中 {totalCorrect}問正解
      </div>
    </div>
  );
}
