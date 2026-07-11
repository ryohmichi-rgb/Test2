import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { fetchTestResults } from "../api";
import type { TestResult, ScopeType } from "../types";

const RANK_COLOR: Record<string, string> = { S: "#d69e2e", A: "#38a169", B: "#4c51bf", C: "#718096" };
const LINE = "#4c51bf";

type Filter = "all" | ScopeType;
const FILTERS: { key: Filter; label: string }[] = [
  { key: "all", label: "すべて" },
  { key: "grade", label: "学年まとめ" },
  { key: "stat_type", label: "ステータス別" },
  { key: "unit", label: "単元別" },
];

// スコアの推移をシンプルな折れ線で（単一系列・単色）
function ScoreChart({ results }: { results: TestResult[] }) {
  // 古い→新しい順
  const pts = [...results].reverse();
  const W = 320, H = 160, padX = 28, padY = 18;
  const innerW = W - padX * 2, innerH = H - padY * 2;

  if (pts.length === 0) return null;

  const x = (i: number) => padX + (pts.length === 1 ? innerW / 2 : (i / (pts.length - 1)) * innerW);
  const y = (v: number) => padY + (1 - v / 100) * innerH;

  const linePath = pts.map((p, i) => `${i === 0 ? "M" : "L"} ${x(i).toFixed(1)} ${y(p.score_percent).toFixed(1)}`).join(" ");

  return (
    <div style={{ overflowX: "auto" }}>
      <svg viewBox={`0 0 ${W} ${H}`} width="100%" style={{ maxWidth: 480 }} role="img" aria-label="テスト点数の推移">
        {/* 目盛り 0/50/100 */}
        {[0, 50, 100].map((v) => (
          <g key={v}>
            <line x1={padX} x2={W - padX} y1={y(v)} y2={y(v)} stroke="#edf2f7" strokeWidth="1" />
            <text x={padX - 6} y={y(v) + 3} textAnchor="end" fontSize="9" fill="#a0aec0">{v}</text>
          </g>
        ))}
        {/* 折れ線 */}
        <path d={linePath} fill="none" stroke={LINE} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
        {/* 点 */}
        {pts.map((p, i) => (
          <circle key={p.id} cx={x(i)} cy={y(p.score_percent)} r="4" fill="#fff" stroke={LINE} strokeWidth="2" />
        ))}
        {/* 最新値を直接ラベル */}
        {(() => {
          const last = pts.length - 1;
          return (
            <text x={x(last)} y={y(pts[last].score_percent) - 8} textAnchor="middle" fontSize="10" fontWeight="700" fill={LINE}>
              {pts[last].score_percent}
            </text>
          );
        })()}
      </svg>
    </div>
  );
}

export default function TestHistoryPage() {
  const navigate = useNavigate();
  const studentId = Number(localStorage.getItem("studentId"));
  const [results, setResults] = useState<TestResult[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<Filter>("all");

  useEffect(() => {
    if (!studentId) { navigate("/"); return; }
    fetchTestResults(studentId).then(setResults).finally(() => setLoading(false));
  }, [studentId, navigate]);

  const filtered = useMemo(
    () => (filter === "all" ? results : results.filter((r) => r.scope_type === filter)),
    [results, filter]
  );

  if (loading) return <div className="loading">読み込み中...</div>;

  return (
    <div className="page">
      <header className="page-header">
        <button className="btn-back" onClick={() => navigate("/home")}>← ホーム</button>
        <button className="btn-secondary" onClick={() => navigate("/test")}>テストを受ける</button>
      </header>

      <h2 style={{ fontSize: "1.4rem", fontWeight: 700, marginBottom: "0.25rem" }}>テスト履歴</h2>
      <p style={{ color: "#718096", fontSize: "0.9rem", marginBottom: "1.25rem" }}>点数の推移をふり返れます</p>

      {results.length === 0 ? (
        <div style={{ background: "#fff", borderRadius: 12, padding: "2rem", textAlign: "center", boxShadow: "0 2px 8px rgba(0,0,0,0.06)" }}>
          <p style={{ color: "#718096", marginBottom: "1rem" }}>まだテストを受けていません</p>
          <button className="btn-primary" onClick={() => navigate("/test")}>テストを受ける</button>
        </div>
      ) : (
        <>
          <div className="chip-row" style={{ marginBottom: "1rem" }}>
            {FILTERS.map((f) => (
              <button key={f.key} className={`chip ${filter === f.key ? "chip-on" : ""}`} onClick={() => setFilter(f.key)}>
                {f.label}
              </button>
            ))}
          </div>

          <div style={{ background: "#fff", borderRadius: 14, padding: "1.25rem", boxShadow: "0 2px 8px rgba(0,0,0,0.06)", marginBottom: "1.25rem" }}>
            <ScoreChart results={filtered} />
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: "0.6rem" }}>
            {filtered.map((r) => (
              <div key={r.id} className="history-row">
                <div className="rank-badge-sm" style={{ color: RANK_COLOR[r.rank], borderColor: RANK_COLOR[r.rank] }}>{r.rank}</div>
                <div style={{ flex: 1 }}>
                  <p style={{ fontWeight: 600, fontSize: "0.92rem" }}>{r.scope_label}</p>
                  <p style={{ fontSize: "0.78rem", color: "#a0aec0" }}>
                    {new Date(r.created_at).toLocaleDateString("ja-JP", { year: "numeric", month: "long", day: "numeric" })}
                  </p>
                </div>
                <div style={{ textAlign: "right" }}>
                  <span style={{ fontSize: "1.2rem", fontWeight: 800, color: "#4c51bf" }}>{r.score_percent}</span>
                  <span style={{ fontSize: "0.8rem", color: "#a0aec0" }}>点</span>
                  <p style={{ fontSize: "0.75rem", color: "#a0aec0" }}>{r.correct_count}/{r.total_questions}</p>
                </div>
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
