import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { fetchStudentStats, fetchReferenceStats, updateGoal, fetchCondition } from "../api";
import type { StudentStat, ReferenceStat, Condition } from "../types";
import ReferenceIcon from "../components/ReferenceIcon";

const STAT_COLORS: Record<string, string> = {
  "計算力":    "#4c51bf",
  "数的センス": "#38a169",
  "図形力":    "#d69e2e",
  "文章読解力": "#dd6b20",
  "論理力":    "#805ad5",
};

const REF_MAX = 500;

const defaultGoalDate = () => {
  const d = new Date();
  d.setMonth(d.getMonth() + 3);
  return d.toISOString().slice(0, 10);
};

export default function StatsPage() {
  const navigate = useNavigate();
  const studentId = Number(localStorage.getItem("studentId"));
  const studentName = localStorage.getItem("studentName") || "";

  const [stats, setStats] = useState<StudentStat[]>([]);
  const [refs, setRefs] = useState<ReferenceStat[]>([]);
  const [condition, setCondition] = useState<Condition | null>(null);
  const [loading, setLoading] = useState(true);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [goalValue, setGoalValue] = useState("");
  const [goalDate, setGoalDate] = useState("");
  const [saving, setSaving] = useState(false);

  const [goalRefLabel, setGoalRefLabel] = useState<string | null>(null);
  const [refGoalDate, setRefGoalDate] = useState("");
  const [refSaving, setRefSaving] = useState(false);
  const [savedMessage, setSavedMessage] = useState<string | null>(null);

  useEffect(() => {
    if (!studentId) { navigate("/"); return; }
    Promise.all([fetchStudentStats(studentId), fetchReferenceStats()])
      .then(([s, r]) => { setStats(s); setRefs(r); })
      .finally(() => setLoading(false));
    fetchCondition(studentId).then(setCondition).catch(() => {});
  }, [studentId, navigate]);

  const startEdit = (stat: StudentStat) => {
    setEditingId(stat.stat_type_id);
    setGoalValue(String(stat.goal?.target_value ?? ""));
    setGoalDate(stat.goal?.target_date ?? "");
  };

  const saveGoal = async (statTypeId: number) => {
    if (!goalValue || !goalDate) return;
    setSaving(true);
    try {
      await updateGoal(studentId, statTypeId, Number(goalValue), goalDate);
      const updated = await fetchStudentStats(studentId);
      setStats(updated);
      setEditingId(null);
    } finally {
      setSaving(false);
    }
  };

  const getRefValue = (statTypeId: number, label: string) =>
    refs.find((r) => r.label === label)?.stats.find((s) => s.stat_type_id === statTypeId)?.value;

  const openRefGoal = (label: string) => {
    setGoalRefLabel(label);
    setRefGoalDate(defaultGoalDate());
  };

  const applyReferenceAsGoal = async (ref: ReferenceStat) => {
    if (!refGoalDate) return;
    setRefSaving(true);
    try {
      await Promise.all(
        ref.stats.map((s) => updateGoal(studentId, s.stat_type_id, s.value, refGoalDate))
      );
      const updated = await fetchStudentStats(studentId);
      setStats(updated);
      setGoalRefLabel(null);
      setSavedMessage(`「${ref.label}」を目標に設定しました！`);
      setTimeout(() => setSavedMessage(null), 3000);
    } finally {
      setRefSaving(false);
    }
  };

  if (loading) return <div className="loading">読み込み中...</div>;

  const maxValue = 500;

  return (
    <div className="page">
      <header className="page-header">
        <button className="btn-back" onClick={() => navigate("/grades")}>← もどる</button>
        <button className="btn-secondary" onClick={() => navigate(`/progress/${studentId}`)}>学習進捗</button>
      </header>

      <h2 style={{ fontSize: "1.4rem", fontWeight: 700, marginBottom: "0.25rem" }}>
        {studentName}さんのステータス
      </h2>
      <p style={{ color: "#718096", fontSize: "0.9rem", marginBottom: "1.75rem" }}>
        問題に正解するとステータスが上がります
      </p>

      {/* さびつき（コンディション）のナッジ。数字は下げず、状態だけ伝える */}
      {condition && condition.rust_percent > 0 && (
        <div className="rust-banner">
          <span className="rust-icon">🛡️</span>
          <div>
            <p style={{ fontWeight: 700, fontSize: "0.9rem" }}>
              さびつき −{condition.rust_percent}%（{condition.idle_days}日お休み中）
            </p>
            <p style={{ fontSize: "0.8rem", opacity: 0.9 }}>1問でも解けば元にもどるよ。実力の記録は消えません。</p>
          </div>
        </div>
      )}

      {/* 目標サマリー（目標を設定しているステータスの進捗一覧） */}
      {stats.some((s) => s.goal) && (
        <div className="goal-summary">
          <h3 style={{ fontSize: "0.95rem", fontWeight: 700, color: "#4a5568", marginBottom: "0.75rem" }}>目標の進捗</h3>
          <div style={{ display: "flex", flexDirection: "column", gap: "0.7rem" }}>
            {stats.filter((s) => s.goal).map((s) => {
              const color = STAT_COLORS[s.name] ?? "#4c51bf";
              const pct = Math.min((s.value / s.goal!.target_value) * 100, 100);
              const achieved = s.value >= s.goal!.target_value;
              return (
                <div key={s.stat_type_id}>
                  <div style={{ display: "flex", justifyContent: "space-between", fontSize: "0.82rem", marginBottom: "0.25rem" }}>
                    <span style={{ fontWeight: 600, color }}>{s.name}</span>
                    {achieved
                      ? <span style={{ color: "#38a169", fontWeight: 700 }}>達成 ✓</span>
                      : <span style={{ color: "#718096" }}>あと {s.goal!.target_value - s.value}pt</span>}
                  </div>
                  <div style={{ height: 8, background: "#edf2f7", borderRadius: 4, overflow: "hidden" }}>
                    <div style={{ height: "100%", width: `${pct}%`, background: achieved ? "#38a169" : color, borderRadius: 4, transition: "width 0.4s" }} />
                  </div>
                  <div style={{ fontSize: "0.72rem", color: "#a0aec0", marginTop: "0.15rem" }}>
                    {s.value} / {s.goal!.target_value}（{new Date(s.goal!.target_date).toLocaleDateString("ja-JP", { month: "long", day: "numeric" })}まで）
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      <div className={`stats-list ${condition && condition.rust_percent > 0 ? "rusty" : ""}`} style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
        {stats.map((stat) => {
          const color = STAT_COLORS[stat.name] ?? "#4c51bf";
          const fillPct = Math.min((stat.value / maxValue) * 100, 100);
          const goalPct = stat.goal ? Math.min((stat.goal.target_value / maxValue) * 100, 100) : null;
          const isEditing = editingId === stat.stat_type_id;

          return (
            <div key={stat.stat_type_id} className="stats-card">
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "0.5rem" }}>
                <div>
                  <span style={{ fontWeight: 700, fontSize: "1.05rem", color }}>{stat.name}</span>
                  <span style={{ marginLeft: "0.5rem", fontSize: "1.5rem", fontWeight: 800, color }}>{stat.value}</span>
                  {stat.goal && (
                    <span style={{ color: "#a0aec0", fontSize: "0.9rem" }}> / 目標 {stat.goal.target_value}</span>
                  )}
                </div>
                <button
                  className="btn-hint"
                  onClick={() => isEditing ? setEditingId(null) : startEdit(stat)}
                  style={{ fontSize: "0.8rem", padding: "0.3rem 0.75rem" }}
                >
                  {isEditing ? "とじる" : "目標を設定"}
                </button>
              </div>

              {/* ステータスバー */}
              <div className="stats-bar-wrap">
                <div className="stats-bar-fill" style={{ width: `${fillPct}%`, background: color }} />
                {goalPct !== null && (
                  <div className="stats-bar-goal-marker" style={{ left: `${goalPct}%` }} />
                )}
              </div>

              {/* 参考値 */}
              <div style={{ display: "flex", gap: "1rem", marginTop: "0.5rem", flexWrap: "wrap" }}>
                {["中学卒業レベル", "高校受験（公立）", "数学の先生"].map((label) => {
                  const val = getRefValue(stat.stat_type_id, label);
                  if (!val) return null;
                  return (
                    <span key={label} style={{ fontSize: "0.75rem", color: "#a0aec0" }}>
                      {label}: <strong style={{ color: "#718096" }}>{val}</strong>
                    </span>
                  );
                })}
              </div>

              {/* 目標設定フォーム */}
              {isEditing && (
                <div className="goal-form">
                  <div style={{ display: "flex", gap: "0.75rem", alignItems: "flex-end", flexWrap: "wrap" }}>
                    <div style={{ display: "flex", flexDirection: "column", gap: "0.25rem" }}>
                      <label style={{ fontSize: "0.8rem", color: "#718096" }}>目標の値</label>
                      <input
                        type="number"
                        value={goalValue}
                        onChange={(e) => setGoalValue(e.target.value)}
                        placeholder="例: 300"
                        min={1}
                        max={999}
                        style={{ width: "100px", padding: "0.4rem 0.6rem", border: "2px solid #e2e8f0", borderRadius: "6px", fontSize: "0.95rem" }}
                      />
                    </div>
                    <div style={{ display: "flex", flexDirection: "column", gap: "0.25rem" }}>
                      <label style={{ fontSize: "0.8rem", color: "#718096" }}>目標の日付</label>
                      <input
                        type="date"
                        value={goalDate}
                        onChange={(e) => setGoalDate(e.target.value)}
                        style={{ padding: "0.4rem 0.6rem", border: "2px solid #e2e8f0", borderRadius: "6px", fontSize: "0.95rem" }}
                      />
                    </div>
                    <button
                      className="btn-primary"
                      onClick={() => saveGoal(stat.stat_type_id)}
                      disabled={saving || !goalValue || !goalDate}
                      style={{ padding: "0.45rem 1rem", fontSize: "0.9rem" }}
                    >
                      {saving ? "保存中..." : "保存"}
                    </button>
                  </div>
                </div>
              )}

              <p style={{ fontSize: "0.8rem", color: "#a0aec0", marginTop: "0.5rem" }}>{stat.description}</p>
            </div>
          );
        })}
      </div>

      {/* 参考ステータス */}
      <div style={{ marginTop: "2.5rem" }}>
        <h3 style={{ fontSize: "1rem", fontWeight: 700, marginBottom: "0.35rem", color: "#4a5568" }}>参考ステータス</h3>
        <p style={{ fontSize: "0.85rem", color: "#a0aec0", marginBottom: "1rem" }}>
          カードを選ぶと、そのステータスをそのまま目標に設定できます
        </p>

        <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
          {refs.map((ref) => {
            const isSettingGoal = goalRefLabel === ref.label;
            const sortedStats = [...ref.stats].sort((a, b) => b.value - a.value);

            return (
              <div key={ref.label} className="ref-card">
                <div className="ref-card-head">
                  <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
                    <span className="ref-icon" aria-hidden="true"><ReferenceIcon label={ref.label} size={54} /></span>
                    <span style={{ fontWeight: 700, fontSize: "1.05rem", color: "#2d3748" }}>{ref.label}</span>
                  </div>
                  {!isSettingGoal && (
                    <button className="btn-secondary" onClick={() => openRefGoal(ref.label)} style={{ fontSize: "0.8rem", padding: "0.4rem 0.8rem" }}>
                      この目標にする
                    </button>
                  )}
                </div>

                {/* 棒グラフ */}
                <div className="ref-chart">
                  {sortedStats.map((s) => {
                    const color = STAT_COLORS[s.name] ?? "#4c51bf";
                    const pct = Math.min((s.value / REF_MAX) * 100, 100);
                    return (
                      <div key={s.stat_type_id} className="ref-bar-row">
                        <span className="ref-bar-label">{s.name}</span>
                        <div className="ref-bar-track">
                          <div className="ref-bar-fill" style={{ width: `${pct}%`, background: color }} />
                        </div>
                        <span className="ref-bar-value" style={{ color }}>{s.value}</span>
                      </div>
                    );
                  })}
                </div>

                {/* 目標にする日付選択 */}
                {isSettingGoal && (
                  <div className="goal-form" style={{ marginTop: "1rem" }}>
                    <p style={{ fontSize: "0.85rem", color: "#4a5568", marginBottom: "0.5rem", fontWeight: 600 }}>
                      いつまでに達成しますか？
                    </p>
                    <div style={{ display: "flex", gap: "0.75rem", alignItems: "center", flexWrap: "wrap" }}>
                      <input
                        type="date"
                        value={refGoalDate}
                        onChange={(e) => setRefGoalDate(e.target.value)}
                        style={{ padding: "0.4rem 0.6rem", border: "2px solid #e2e8f0", borderRadius: "6px", fontSize: "0.95rem" }}
                      />
                      <button className="btn-primary" onClick={() => applyReferenceAsGoal(ref)} disabled={refSaving || !refGoalDate} style={{ padding: "0.45rem 1rem", fontSize: "0.9rem" }}>
                        {refSaving ? "設定中..." : "目標にする"}
                      </button>
                      <button className="btn-hint" onClick={() => setGoalRefLabel(null)} style={{ fontSize: "0.85rem" }}>
                        キャンセル
                      </button>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* 保存トースト */}
      {savedMessage && (
        <div className="toast">{savedMessage}</div>
      )}
    </div>
  );
}
