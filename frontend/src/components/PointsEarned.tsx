import type { AnswerResult } from "../types";

// 正解したときに獲得ポイントを見せる。
// 同じ問題の解き直しは満点の20%になるが、黙って減ると「バグ？」と思われるので、
// 減額されたこと（と、時間がたてば戻ること）をここで伝える。
export default function PointsEarned({ result }: { result: AnswerResult }) {
  if (!result.is_correct || result.points <= 0) return null;

  return (
    <p className="points-earned">
      <strong>+{result.points}pt</strong>
      {result.is_repeat && (
        <span className="points-earned-note">
          ふくしゅう（少し前に解いた問題だよ。時間がたつともとの点にもどるよ）
        </span>
      )}
    </p>
  );
}
