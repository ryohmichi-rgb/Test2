import { useRef } from "react";

// 答えの入力欄（記述式）。演習・問題集・テスト・復習・昇格試験・今日の一問で共用する。
//
// キーパッドを付けているのは、スマホでもPCでもキーボードで答えを打つのがつらいため。
// 答えに出てくる文字は `+-/0123456789:abx` の17種類だけで（seeds全94問を調査）、
// 小数点も使わない。だからこの範囲を並べたキーパッドで**すべての答えが打てる**。
//
// inputMode="none" はスマホのソフトキーボードを出さないための指定。
// PCの物理キーボードには影響しないので、打ちたい人はそのまま打てる。
const KEYPAD_ROWS: string[][] = [
  ["7", "8", "9", "⌫"],
  ["4", "5", "6", "/"],
  ["1", "2", "3", "x"],
  ["0", "-", "+", ":"],
  ["a", "b"],
];

const BACKSPACE = "⌫";

// 答えが7文字（"500-60x"）を超えることは今のところ無い。
// 打ち間違いで延々と伸びるのを防ぐぶんの余裕を見て上限を置く。
const MAX_LENGTH = 20;

type Props = {
  value: string;
  onChange: (v: string) => void;
  disabled?: boolean;
  onEnter?: () => void;
  autoFocus?: boolean;
};

export default function AnswerInput({ value, onChange, disabled, onEnter, autoFocus }: Props) {
  const ref = useRef<HTMLInputElement>(null);

  // カーソルの位置に差し込む（末尾に足すだけだと、打ち間違いの直しがつらい）
  const press = (key: string) => {
    if (disabled) return;
    const el = ref.current;
    const start = el?.selectionStart ?? value.length;
    const end = el?.selectionEnd ?? value.length;

    let next: string;
    let caret: number;
    if (key === BACKSPACE) {
      if (start !== end) {
        next = value.slice(0, start) + value.slice(end);   // 選択ぶんを消す
        caret = start;
      } else if (start > 0) {
        next = value.slice(0, start - 1) + value.slice(start);
        caret = start - 1;
      } else {
        return;
      }
    } else {
      if (value.length - (end - start) >= MAX_LENGTH) return;
      next = value.slice(0, start) + key + value.slice(end);
      caret = start + key.length;
    }

    onChange(next);
    // 値が入ったあとにカーソルを戻す
    requestAnimationFrame(() => {
      el?.focus();
      el?.setSelectionRange(caret, caret);
    });
  };

  return (
    <>
      <input
        ref={ref}
        type="text"
        className="answer-input"
        inputMode="none"
        value={value}
        onChange={(e) => onChange(e.target.value.slice(0, MAX_LENGTH))}
        onKeyDown={(e) => e.key === "Enter" && onEnter?.()}
        placeholder="答えを入力..."
        disabled={disabled}
        autoFocus={autoFocus}
      />

      <div className="keypad" role="group" aria-label="答えの入力キー">
        {KEYPAD_ROWS.map((row, i) => (
          <div className="keypad-row" key={i}>
            {row.map((key) => (
              <button
                key={key}
                type="button"
                className={`keypad-key${key === BACKSPACE ? " keypad-key-del" : ""}`}
                // 押しても入力欄からフォーカスを奪わない（カーソル位置を保つ）
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => press(key)}
                disabled={disabled}
                aria-label={key === BACKSPACE ? "1文字消す" : key}
              >
                {key}
              </button>
            ))}
          </div>
        ))}
      </div>
    </>
  );
}
