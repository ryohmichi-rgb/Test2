import { useState } from "react";
import { fetchAiUsage, askTeacher } from "../api";
import type { AskKind } from "../types";
import MathText from "./MathText";

// 「先生に聞く」— 問題を解く画面で共通に使う。今解いている問題を渡すと、
// その問題の文脈つきで Claude がヒント・解き方・理由を返す（答えは丸投げしない）。
// テスト画面では使わない（実力測定のため）。

// 先生（Claude）の返答をMathTextで描ける形にならす保険。
// 記法はシステムプロンプトで指定している（claude_teacher.rb）が、生成AIなので
// たまに外れる。外れたときに画面へ記号が出ないよう、ここで最低限だけ整える。
//   $$…$$ → $…$   MathTextは行内の `$…$` だけを組版するので、$$ だと $ が残る
//   **太字** → 太字  MathTextはMarkdownを解釈しないので ** がそのまま見えてしまう
function normalizeAnswer(text: string): string {
  return text.replace(/\$\$/g, "$").replace(/\*\*(.+?)\*\*/g, "$1");
}

const PRESETS: { kind: AskKind; label: string; emoji: string }[] = [
  { kind: "hint", label: "ヒント", emoji: "💡" },
  { kind: "approach", label: "解き方", emoji: "🪜" },
  { kind: "why", label: "なぜ？", emoji: "🤔" },
];

export default function AskTeacher({ studentId, problemId }: { studentId: number; problemId: number }) {
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [answer, setAnswer] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [remaining, setRemaining] = useState<number | null>(null);
  const [question, setQuestion] = useState("");

  const toggle = () => {
    const next = !open;
    setOpen(next);
    if (next && remaining === null) {
      fetchAiUsage(studentId).then((u) => setRemaining(u.remaining)).catch(() => {});
    }
  };

  const ask = async (kind: AskKind, freeText?: string) => {
    if (loading) return;
    setLoading(true);
    setError(null);
    setAnswer(null);
    try {
      const res = await askTeacher(studentId, problemId, kind, freeText);
      setRemaining(res.remaining);
      if (res.answer) setAnswer(res.answer);
      else setError(res.error || "うまく答えられなかったみたい。");
    } catch {
      setError("うまく先生とつながらなかったみたい。もう一度ためしてね。");
    } finally {
      setLoading(false);
    }
  };

  const askFree = () => {
    const q = question.trim();
    if (!q) return;
    ask("free", q);
  };

  const outOfQuota = remaining !== null && remaining <= 0;

  return (
    <div className="ask-teacher">
      <button className="ask-teacher-toggle" onClick={toggle} aria-expanded={open}>
        👨‍🏫 先生に聞く{open ? " ▲" : " ▼"}
      </button>

      {open && (
        <div className="ask-teacher-panel">
          {remaining !== null && (
            <p className="ask-teacher-remaining">
              {outOfQuota ? "今日はここまで！また明日ね。" : `今日はあと ${remaining} 回聞けるよ`}
            </p>
          )}

          <div className="ask-teacher-presets">
            {PRESETS.map((p) => (
              <button
                key={p.kind}
                className="ask-teacher-preset"
                onClick={() => ask(p.kind)}
                disabled={loading || outOfQuota}
              >
                {p.emoji} {p.label}
              </button>
            ))}
          </div>

          <div className="ask-teacher-free">
            <input
              type="text"
              value={question}
              onChange={(e) => setQuestion(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && askFree()}
              placeholder="じゆうに質問…"
              disabled={loading || outOfQuota}
            />
            <button onClick={askFree} disabled={loading || outOfQuota || !question.trim()}>
              聞く
            </button>
          </div>

          {loading && <p className="ask-teacher-thinking">先生が考え中…</p>}
          {/* 返答にも数式が入る（問題文が数式なので先生もLaTeXで返す）。
              MathText は `$...$` だけを組版する軽量版なので、Markdownは使わせない約束を
              システムプロンプト側（claude_teacher.rb）で担保している。 */}
          {answer && (
            <div className="ask-teacher-answer">
              <MathText>{normalizeAnswer(answer)}</MathText>
            </div>
          )}
          {error && <p className="ask-teacher-error">{error}</p>}
        </div>
      )}
    </div>
  );
}
