import { useCallback, useEffect, useRef, useState } from "react";

// 問題を解いている最中の手書きメモ（筆算・途中式）。
// 演習・問題集・テスト・復習・昇格試験で共用する。
//
// 保存はしない。紙と同じ使い捨てで、問題を移れば新しい紙になる（親が key を変えて作り直す）。
// 画像を localStorage に貯めると容量（数MB）をすぐ使い切るし、メモは残す前提のものではない。
//
// 線は画像ではなく**座標の配列**で持つ。こうすると「元に戻す」が配列を1つ減らして
// 描き直すだけで済み、画面の幅が変わっても線が伸び縮みしない。
type Point = { x: number; y: number };
type Stroke = { points: Point[]; erase: boolean };

const PEN_WIDTH = 2.5;
const ERASER_WIDTH = 18;
const HEIGHT = 220;          // 筆算が2〜3個書けるくらい
const MAX_STROKES = 300;     // 際限なく増えないように上限を置く（実用上まず当たらない）

export default function ScratchPad() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const strokesRef = useRef<Stroke[]>([]);
  const drawingRef = useRef(false);
  const [open, setOpen] = useState(false);
  const [erasing, setErasing] = useState(false);
  const [hasInk, setHasInk] = useState(false);

  // 線を全部引き直す。画面幅が変わったときと「元に戻す」で使う。
  const redraw = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    // 高解像度の画面でぼやけないよう、実ピクセルで持って表示サイズに合わせて縮める
    const dpr = window.devicePixelRatio || 1;
    const w = canvas.clientWidth;
    if (canvas.width !== Math.round(w * dpr) || canvas.height !== Math.round(HEIGHT * dpr)) {
      canvas.width = Math.round(w * dpr);
      canvas.height = Math.round(HEIGHT * dpr);
    }
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, w, HEIGHT);
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
    if (!open) return;
    redraw();
    window.addEventListener("resize", redraw);
    return () => window.removeEventListener("resize", redraw);
  }, [open, redraw]);

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

  if (!open) {
    return (
      <button className="btn-hint scratch-toggle" onClick={() => setOpen(true)}>
        ✏️ メモを開く
      </button>
    );
  }

  return (
    <div className="scratch">
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
        <button className="btn-hint scratch-tool" onClick={() => setOpen(false)}>とじる</button>
      </div>

      <canvas
        ref={canvasRef}
        className="scratch-canvas"
        style={{ height: HEIGHT }}
        onPointerDown={start}
        onPointerMove={move}
        onPointerUp={end}
        onPointerCancel={end}
      />
      <p className="scratch-note">メモは答え合わせには使われません。次の問題に進むと消えます。</p>
    </div>
  );
}
