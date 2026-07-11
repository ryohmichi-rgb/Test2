import type { Problem } from "../types";

type Props = {
  problem: Problem;
  value: string;
  onChange: (v: string) => void;
  disabled?: boolean;
  onEnter?: () => void;
};

// 1問を表示する共通コンポーネント（問題集・テスト・演習で再利用）
export default function ProblemView({ problem, value, onChange, disabled, onEnter }: Props) {
  const isMultipleChoice = problem.problem_type === "multiple_choice";

  return (
    <>
      <div className="difficulty-stars">
        {"★".repeat(problem.difficulty)}{"☆".repeat(5 - problem.difficulty)}
      </div>
      <p className="problem-question">{problem.question}</p>

      {isMultipleChoice ? (
        <div className="choices-grid">
          {problem.choices?.map((choice) => (
            <button
              key={choice.id}
              className={`choice-btn ${value === choice.text ? "selected" : ""}`}
              onClick={() => !disabled && onChange(choice.text)}
              disabled={disabled}
            >
              {choice.text}
            </button>
          ))}
        </div>
      ) : (
        <input
          type="text"
          className="answer-input"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && onEnter?.()}
          placeholder="答えを入力..."
          disabled={disabled}
          autoFocus
        />
      )}
    </>
  );
}
