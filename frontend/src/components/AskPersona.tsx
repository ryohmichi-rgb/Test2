import { useState } from "react";
import { fetchPersonaUsage, askPersona } from "../api";
import type { PersonaKind } from "../types";
import MathText from "./MathText";

// 「この人に聞く」— ステータス画面の参考ステータスカードから開く。
// 目の前の問題のヒントは「先生に聞く」（AskTeacher）の役目で、こちらは動機づけ。
// 回数の枠も別（先生20回／こちら5回）。
//
// 返答をMathTextで描ける形にならす保険は先生と同じ理由で置く。記法はサーバ側の
// システムプロンプト（AiSafety::COMMON_RULES）で固定しているが、生成AIなのでたまに外れる。
function normalizeAnswer(text: string): string {
  return text.replace(/\$\$/g, "$").replace(/\*\*(.+?)\*\*/g, "$1");
}

const PRESETS: { kind: PersonaKind; label: string }[] = [
  { kind: "why_study", label: "なんで勉強するの？" },
  { kind: "how_used", label: "仕事でどう使う？" },
  { kind: "childhood", label: "どんな子どもだった？" },
];

// 質問の長さ。サーバ側（AiSafety::MAX_QUESTION_LENGTH）と同じにしておく
const MAX_QUESTION = 200;

type Props = { studentId: number; characterKey: string; label: string; emoji: string };

export default function AskPersona({ studentId, characterKey, label, emoji }: Props) {
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
      fetchPersonaUsage(studentId).then((u) => setRemaining(u.remaining)).catch(() => {});
    }
  };

  const ask = async (kind: PersonaKind, freeText?: string) => {
    if (loading) return;
    setLoading(true);
    setError(null);
    setAnswer(null);
    try {
      const res = await askPersona(studentId, characterKey, kind, freeText);
      setRemaining(res.remaining);
      if (res.answer) setAnswer(res.answer);
      else setError(res.error || "うまく答えられなかったみたい。");
    } catch {
      setError("うまくつながらなかったみたい。もう一度ためしてね。");
    } finally {
      setLoading(false);
    }
  };

  const askFree = () => {
    const q = question.trim();
    if (!q) return;
    setQuestion("");
    ask("free", q);
  };

  return (
    <div className="ask-persona">
      <button className="btn-hint ask-persona-toggle" onClick={toggle}>
        {emoji} {label}に聞く {open ? "▲" : "▼"}
      </button>

      {open && (
        <div className="ask-persona-panel">
          <p className="ask-persona-lead">
            勉強する意味を聞いてみよう。
            {remaining !== null && <span className="ask-persona-remaining">今日はあと{remaining}回</span>}
          </p>

          <div className="ask-persona-presets">
            {PRESETS.map((p) => (
              <button key={p.kind} className="btn-hint ask-persona-preset" disabled={loading} onClick={() => ask(p.kind)}>
                {p.label}
              </button>
            ))}
          </div>

          <div className="ask-persona-free">
            <input
              type="text"
              value={question}
              maxLength={MAX_QUESTION}
              onChange={(e) => setQuestion(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && askFree()}
              placeholder="じぶんで聞いてみる…"
              disabled={loading}
            />
            <button className="btn-secondary" disabled={loading || !question.trim()} onClick={askFree}>
              聞く
            </button>
          </div>

          {loading && <p className="ask-persona-loading">考えているところ…</p>}
          {error && <p className="error-text">{error}</p>}
          {answer && (
            <div className="ask-persona-answer">
              <MathText>{normalizeAnswer(answer)}</MathText>
            </div>
          )}

          <p className="ask-persona-note">
            解き方は教えてもらえません（それは「先生に聞く」で）。
          </p>
        </div>
      )}
    </div>
  );
}
