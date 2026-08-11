import { useCallback, useEffect, useRef, useState } from "react";

// 問題を解いている最中のメモ（筆算・途中式）。
// 演習・問題集・テスト・復習・昇格試験で共用する。
//
// メモの中身は保存しない。紙と同じ使い捨てで、問題を移れば新しい紙になる
// （親が key={problem.id} を渡して作り直す）。
// ただし**使い方の設定（開いているか・手書きか文字か・広さ）は localStorage に残す**。
// 問題ごとに作り直される作りなので、残さないと毎問「開く」「ひろげる」を押し直すことになる。
type Point = { x: number; y: number };
type Stroke = { points: Point[]; erase: boolean };

const PEN_WIDTH = 2.5;
const ERASER_WIDTH = 18;
const MAX_STROKES = 300;   // 際限なく増えないように上限を置く（実用上まず当たらない）

// 高さは2段階。既定でも筆算が3つほど書ける広さにし、足りなければ「ひろげる」で倍近くまで。
const SIZES = { normal: 280, wide: 520 } as const;
type Size = keyof typeof SIZES;

const KEY_OPEN = "scratchOpen";
const KEY_MODE = "scratchMode";
const KEY_SIZE = "scratchSize";

const read = (key: string, fallback: string) => {
  if (typeof localStorage === "undefined") return fallback;
  return localStorage.getItem(key) ?? fallback;
};

export default function ScratchPad() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const strokesRef = useRef<Stroke[]>([]);
  const drawingRef = useRef(false);

  const [open, setOpen] = useState(() => read(KEY_OPEN, "off") === "on");
  const [mode, setMode] = useState<"draw" | "text">(() => (read(KEY_MODE, "draw") === "text" ? "text" : "draw"));
  const [size, setSize] = useState<Size>(() => (read(KEY_SIZE, "normal") === "wide" ? "wide" : "normal"));
  const [erasing, setErasing] = useState(false);
  const [hasInk, setHasInk] = useState(false);
  const [text, setText] = useState("");   // 文字メモ。問題が変わればこの state ごと作り直される

  const height = SIZES[size];

  const remember = (key: string, value: string) => localStorage.setItem(key, value);

  // 線を全部引き直す。広さを変えたとき・画面幅が変わったとき・「もどす」で使う。
  const redraw = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    // 高解像度の画面でぼやけないよう、実ピクセルで持って表示サイズに合わせて縮める
    const dpr = window.devicePixelRatio || 1;
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    if (canvas.width !== Math.round(w * dpr) || canvas.height !== Math.round(h * dpr)) {
      canvas.width = Math.round(w * dpr);
      canvas.height = Math.round(h * dpr);
    }
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, w, h);
    ctx.lineCap = "round";
    ctx.lineJoin = "round";

    for (const stroke of strokesRef.current) {
      if (stroke.points.length === 0) continue;
      ctx.globalCompositeOperation = stroke.erase ? "destination-out" : "source-over";
      ctx.strokeStyle = "#2d3748";
      ctx.lineWidth = stroke.erase ? ERASER_WIDTH : PEN_WIDTH;
      ctx.beginPath();
      ctx.moveTo(stroke.points[0].x, stroke.points[0].y);
      for (const p of stroke.points.slice(1)) ctx.lineTo(p.x, p.y);
      // 点をひとつ打っただけのときも印が残るようにする
      if (stroke.points.length === 1) ctx.lineTo(stroke.points[0].x + 0.1, stroke.points[0].y);
      ctx.stroke();
    }
    ctx.globalCompositeOperation = "source-over";
  }, []);

  useEffect(() => {
    if (!open || mode !== "draw") return;
    redraw();
    window.addEventListener("resize", redraw);
    return () => window.removeEventListener("resize", redraw);
  }, [open, mode, size, redraw]);

  const pointOf = (e: React.PointerEvent<HTMLCanvasElement>): Point => {
    const r = e.currentTarget.getBoundingClientRect();
    return { x: e.clientX - r.left, y: e.clientY - r.top };
  };

  const start = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (strokesRef.current.length >= MAX_STROKES) return;
    e.currentTarget.setPointerCapture(e.pointerId);  // 指が枠の外に出ても線が続くように
    drawingRef.current = true;
    strokesRef.current.push({ points: [pointOf(e)], erase: erasing });
    setHasInk(true);
    redraw();
  };

  const move = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (!drawingRef.current) return;
    strokesRef.current[strokesRef.current.length - 1].points.push(pointOf(e));
    redraw();
  };

  const end = () => { drawingRef.current = false; };

  const undo = () => {
    strokesRef.current.pop();
    setHasInk(strokesRef.current.length > 0);
    redraw();
  };

  const clear = () => {
    strokesRef.current = [];
    setHasInk(false);
    redraw();
  };

  const switchMode = (next: "draw" | "text") => { setMode(next); remember(KEY_MODE, next); };
  const switchSize = () => {
    const next: Size = size === "normal" ? "wide" : "normal";
    setSize(next);
    remember(KEY_SIZE, next);
  };
  const toggleOpen = (next: boolean) => { setOpen(next); remember(KEY_OPEN, next ? "on" : "off"); };

  if (!open) {
    return (
      <button className="btn-hint scratch-toggle" onClick={() => toggleOpen(true)}>
        ✏️ メモを開く
      </button>
    );
  }

  return (
    <div className="scratch">
      <div className="scratch-bar">
        <button
          className={`btn-hint scratch-tool${mode === "draw" ? " on" : ""}`}
          onClick={() => switchMode("draw")}
          aria-pressed={mode === "draw"}
        >
          ✏️ 手書き
        </button>
        <button
          className={`btn-hint scratch-tool${mode === "text" ? " on" : ""}`}
          onClick={() => switchMode("text")}
          aria-pressed={mode === "text"}
        >
          ⌨️ 文字
        </button>
        <button className="btn-hint scratch-tool" onClick={switchSize}>
          {size === "normal" ? "⤢ ひろげる" : "⤡ ちいさく"}
        </button>
        <button className="btn-hint scratch-tool" onClick={() => toggleOpen(false)}>とじる</button>
      </div>

      {mode === "draw" ? (
        <>
          <div className="scratch-bar">
            <button
              className={`btn-hint scratch-tool${erasing ? "" : " on"}`}
              onClick={() => setErasing(false)}
              aria-pressed={!erasing}
            >
              ✏️ ペン
            </button>
            <button
              className={`btn-hint scratch-tool${erasing ? " on" : ""}`}
              onClick={() => setErasing(true)}
              aria-pressed={erasing}
            >
              ⬜ 消しゴム
            </button>
            <button className="btn-hint scratch-tool" onClick={undo} disabled={!hasInk}>もどす</button>
            <button className="btn-hint scratch-tool" onClick={clear} disabled={!hasInk}>ぜんぶ消す</button>
          </div>

          <canvas
            ref={canvasRef}
            className="scratch-canvas"
            style={{ height }}
            onPointerDown={start}
            onPointerMove={move}
            onPointerUp={end}
            onPointerCancel={end}
          />
        </>
      ) : (
        // 文字のメモ。答えの入力欄と違って自由に打つので、ソフトキーボードはふつうに出す
        <textarea
          className="scratch-text"
          style={{ height }}
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="式や考えたことをメモできます"
        />
      )}

      <p className="scratch-note">メモは答え合わせには使われません。次の問題に進むと消えます。</p>
    </div>
  );
}
