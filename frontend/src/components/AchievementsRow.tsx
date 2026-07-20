import type { Badge } from "../types";

export default function AchievementsRow({ badges }: { badges: Badge[] }) {
  if (badges.length === 0) return null;
  const earnedCount = badges.filter((b) => b.earned).length;

  return (
    <div className="achievements">
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.6rem" }}>
        <h3 style={{ fontSize: "0.95rem", fontWeight: 700, color: "#4a5568" }}>じっせき</h3>
        <span style={{ fontSize: "0.8rem", color: "#a0aec0" }}>{earnedCount} / {badges.length}</span>
      </div>
      <div className="badge-grid">
        {badges.map((b) => (
          <div key={b.key} className={`badge ${b.earned ? "badge-on" : "badge-off"}`} title={b.label}>
            <span className="badge-emoji">{b.emoji}</span>
            <span className="badge-label">{b.label}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
