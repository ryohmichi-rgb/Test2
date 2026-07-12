import { useState } from "react";
import type { Growth, GrowthPoint } from "../types";

const STAT_COLORS: Record<string, string> = {
  "計算力": "#4c51bf",
  "数的センス": "#38a169",
  "図形力": "#d69e2e",
  "文章読解力": "#dd6b20",
  "論理力": "#805ad5",
};
const TOTAL_COLOR = "#4c51bf";

type Series = { name: string; color: string; points: GrowthPoint[] };

function niceMax(v: number) {
  if (v <= 0) return 100;
  const pow = Math.pow(10, Math.floor(Math.log10(v)));
  return Math.ceil(v / pow) * pow;
}

function Chart({ series, labels }: { series: Series[]; labels: string[] }) {
  const W = 340, H = 180, padL = 30, padR = 12, padT = 14, padB = 24;
  const innerW = W - padL - padR, innerH = H - padT - padB;
  const n = labels.length;
  const maxV = niceMax(Math.max(1, ...series.flatMap((s) => s.points.map((p) => p.value))));

  const x = (i: number) => padL + (n === 1 ? innerW / 2 : (i / (n - 1)) * innerW);
  const y = (v: number) => padT + (1 - v / maxV) * innerH;

  // x軸ラベルは最大4つに間引く
  const labelIdx = n <= 4 ? labels.map((_, i) => i) : [0, Math.round((n - 1) / 3), Math.round((2 * (n - 1)) / 3), n - 1];

  return (
    <div style={{ overflowX: "auto" }}>
      <svg viewBox={`0 0 ${W} ${H}`} width="100%" style={{ maxWidth: 520 }} role="img" aria-label="成長曲線">
        {[0, maxV / 2, maxV].map((v) => (
          <g key={v}>
            <line x1={padL} x2={W - padR} y1={y(v)} y2={y(v)} stroke="#edf2f7" strokeWidth="1" />
            <text x={padL - 5} y={y(v) + 3} textAnchor="end" fontSize="9" fill="#a0aec0">{Math.round(v)}</text>
          </g>
        ))}
        {labelIdx.map((i) => (
          <text key={i} x={x(i)} y={H - 8} textAnchor="middle" fontSize="9" fill="#a0aec0">{labels[i]}</text>
        ))}
        {series.map((s) => (
          <g key={s.name}>
            <path
              d={s.points.map((p, i) => `${i === 0 ? "M" : "L"} ${x(i).toFixed(1)} ${y(p.value).toFixed(1)}`).join(" ")}
              fill="none" stroke={s.color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"
            />
            {n === 1 && <circle cx={x(0)} cy={y(s.points[0].value)} r="4" fill="#fff" stroke={s.color} strokeWidth="2" />}
          </g>
        ))}
      </svg>
    </div>
  );
}

export default function GrowthChart({ growth }: { growth: Growth }) {
  const [tab, setTab] = useState<"total" | "stat">("total");
  const labels = growth.total.map((p) => p.label);

  const totalSeries: Series[] = [{ name: "合計学力", color: TOTAL_COLOR, points: growth.total }];
  const statSeries: Series[] = growth.by_stat.map((s) => ({
    name: s.stat_name,
    color: STAT_COLORS[s.stat_name] ?? "#4c51bf",
    points: s.series,
  }));

  return (
    <div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.5rem" }}>
        <h3 style={{ fontSize: "0.95rem", fontWeight: 700, color: "#4a5568" }}>成長曲線</h3>
        <div className="chip-row">
          <button className={`chip ${tab === "total" ? "chip-on" : ""}`} style={{ padding: "0.25rem 0.7rem", fontSize: "0.78rem" }} onClick={() => setTab("total")}>合計</button>
          <button className={`chip ${tab === "stat" ? "chip-on" : ""}`} style={{ padding: "0.25rem 0.7rem", fontSize: "0.78rem" }} onClick={() => setTab("stat")}>ステータス別</button>
        </div>
      </div>

      <Chart series={tab === "total" ? totalSeries : statSeries} labels={labels} />

      {tab === "stat" && (
        <div style={{ display: "flex", flexWrap: "wrap", gap: "0.5rem 0.9rem", marginTop: "0.5rem", justifyContent: "center" }}>
          {statSeries.map((s) => (
            <span key={s.name} style={{ display: "inline-flex", alignItems: "center", gap: "0.3rem", fontSize: "0.75rem", color: "#718096" }}>
              <span style={{ width: 10, height: 3, background: s.color, borderRadius: 2, display: "inline-block" }} />
              {s.name}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}
