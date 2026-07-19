import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { fetchLearningPlan } from "../api";
import type { LearningPlan } from "../types";

const STAT_COLORS: Record<string, string> = {
  "計算力":    "#4c51bf",
  "数的センス": "#38a169",
  "図形力":    "#d69e2e",
  "文章読解力": "#dd6b20",
  "論理力":    "#805ad5",
};

export default function PlanPage() {
  const navigate = useNavigate();
  const studentId = Number(localStorage.getItem("studentId"));
  const studentName = localStorage.getItem("studentName") || "";
  const [plan, setPlan] = useState<LearningPlan | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!studentId) { navigate("/"); return; }
    fetchLearningPlan(studentId)
      .then(setPlan)
      .finally(() => setLoading(false));
  }, [studentId, navigate]);

  if (loading) return <div className="loading">読み込み中...</div>;

  const hasGoals = plan && plan.goals_summary.length > 0;
  const hasPlan = plan && plan.today_plan.length > 0;

  return (
    <div className="page">
      <header className="page-header">
        <button className="btn-back" onClick={() => navigate("/grades")}>← もどる</button>
        <button className="btn-secondary" onClick={() => navigate("/stats")}>ステータス</button>
      </header>

      <h2 style={{ fontSize: "1.4rem", fontWeight: 700, marginBottom: "0.25rem" }}>
        {studentName}さんの学習プラン
      </h2>
      <p style={{ color: "#718096", fontSize: "0.9rem", marginBottom: "1.75rem" }}>
        目標から逆算した今日やるべき学習です
      </p>

      {!hasGoals && (
        <div style={{ background: "#fff", borderRadius: "12px", padding: "2rem", textAlign: "center", boxShadow: "0 2px 8px rgba(0,0,0,0.06)" }}>
          <p style={{ color: "#718096", marginBottom: "1rem" }}>目標が設定されていません</p>
          <button className="btn-primary" onClick={() => navigate("/stats")}>
            目標を設定する
          </button>
        </div>
      )}

      {hasGoals && (
        <>
          {/* 今日のプラン */}
          <section style={{ marginBottom: "2rem" }}>
            <h3 style={{ fontSize: "1rem", fontWeight: 700, color: "#4a5568", marginBottom: "0.75rem" }}>
              今日やること
            </h3>
            {!hasPlan ? (
              <div style={{ background: "#f0fff4", border: "2px solid #68d391", borderRadius: "12px", padding: "1.5rem", textAlign: "center" }}>
                <p style={{ fontSize: "1.5rem", marginBottom: "0.5rem" }}>🎉</p>
                <p style={{ fontWeight: 700, color: "#276749" }}>すべての目標を達成中です！</p>
                <p style={{ color: "#38a169", fontSize: "0.9rem", marginTop: "0.25rem" }}>引き続き学習を続けましょう</p>
              </div>
            ) : (
              <div style={{ display: "flex", flexDirection: "column", gap: "0.75rem" }}>
                {plan.today_plan.map((unit) => {
                  const color = STAT_COLORS[unit.stat_name] ?? "#4c51bf";
                  return (
                    <div key={unit.unit_id} className="plan-unit-card" onClick={() => navigate(`/units/${unit.unit_id}/practice`)}>
                      <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
                        <div style={{ background: color, color: "#fff", borderRadius: "50%", width: 32, height: 32, display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 800, fontSize: "0.9rem", flexShrink: 0 }}>
                          {unit.priority}
                        </div>
                        <div style={{ flex: 1 }}>
                          <p style={{ fontWeight: 600, fontSize: "0.95rem", marginBottom: "0.2rem" }}>{unit.unit_title}</p>
                          <div style={{ display: "flex", gap: "0.75rem", alignItems: "center" }}>
                            <span style={{ fontSize: "0.78rem", color, fontWeight: 600, background: `${color}18`, borderRadius: "4px", padding: "0.1rem 0.4rem" }}>
                              {unit.stat_name}
                            </span>
                            {unit.is_new ? (
                              <span style={{ fontSize: "0.78rem", color: "#805ad5" }}>未着手</span>
                            ) : (
                              <span style={{ fontSize: "0.78rem", color: "#718096" }}>
                                正答率 {Math.round((unit.accuracy ?? 0) * 100)}%
                              </span>
                            )}
                            <span style={{ fontSize: "0.78rem", color: "#48bb78", marginLeft: "auto" }}>
                              +{unit.estimated_points}pt 予定
                            </span>
                          </div>
                        </div>
                        <span style={{ color: "#a0aec0", fontSize: "1.2rem" }}>›</span>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </section>

          {/* 目標の進捗サマリー */}
          <section>
            <h3 style={{ fontSize: "1rem", fontWeight: 700, color: "#4a5568", marginBottom: "0.75rem" }}>
              目標の進捗
            </h3>
            <div style={{ display: "flex", flexDirection: "column", gap: "0.75rem" }}>
              {plan.goals_summary.map((goal) => {
                const color = STAT_COLORS[goal.stat_name] ?? "#4c51bf";
                const pct = Math.min((goal.current / goal.target) * 100, 100);
                return (
                  <div key={goal.stat_type_id} style={{ background: "#fff", borderRadius: "12px", padding: "1rem 1.25rem", boxShadow: "0 2px 8px rgba(0,0,0,0.06)" }}>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.5rem" }}>
                      <span style={{ fontWeight: 700, color }}>{goal.stat_name}</span>
                      {goal.achieved ? (
                        <span style={{ fontSize: "0.8rem", color: "#38a169", fontWeight: 600 }}>達成済み ✓</span>
                      ) : (
                        <span style={{ fontSize: "0.8rem", color: "#718096" }}>残り {goal.days_remaining}日</span>
                      )}
                    </div>
                    <div style={{ height: 8, background: "#e2e8f0", borderRadius: 4, overflow: "hidden", marginBottom: "0.4rem" }}>
                      <div style={{ height: "100%", width: `${pct}%`, background: color, borderRadius: 4, transition: "width 0.4s" }} />
                    </div>
                    <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.8rem", color: "#718096" }}>
                      <span>現在: <strong style={{ color }}>{goal.current}</strong></span>
                      <span>目標: <strong>{goal.target}</strong>（{new Date(goal.target_date).toLocaleDateString("ja-JP", { month: "long", day: "numeric" })}）</span>
                    </div>
                    {!goal.achieved && (
                      <p style={{ fontSize: "0.78rem", color: "#a0aec0", marginTop: "0.35rem" }}>
                        1日あたり {goal.points_per_day}pt 必要（残り {goal.points_needed}pt）
                      </p>
                    )}
                  </div>
                );
              })}
            </div>
          </section>
        </>
      )}
    </div>
  );
}
