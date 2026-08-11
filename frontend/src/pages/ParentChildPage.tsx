import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router";
import { fetchChildren, fetchGrowth, fetchDailyQuota, fetchStudentStats, fetchAchievements, fetchCondition, fetchTestResults } from "../api";
import type { Child, Growth, DailyQuota, StudentStat, Badge, Condition, TestResult } from "../types";
import GrowthChart from "../components/GrowthChart";

// 子ども1人の学習の様子。子どもが見ている画面の「読み取り分」をまとめて出す。
// 操作はできない（保護者は見る専用）。
export default function ParentChildPage() {
  const navigate = useNavigate();
  const { childId } = useParams<{ childId: string }>();
  const id = Number(childId);

  const [child, setChild] = useState<Child | null>(null);
  const [growth, setGrowth] = useState<Growth | null>(null);
  const [quota, setQuota] = useState<DailyQuota | null>(null);
  const [stats, setStats] = useState<StudentStat[]>([]);
  const [badges, setBadges] = useState<Badge[]>([]);
  const [condition, setCondition] = useState<Condition | null>(null);
  const [tests, setTests] = useState<TestResult[]>([]);
  const [denied, setDenied] = useState(false);

  useEffect(() => {
    if (!id) return;
    fetchChildren().then((cs) => {
      const found = cs.find((c) => c.id === id);
      if (!found) { setDenied(true); return; }
      setChild(found);
    }).catch(() => setDenied(true));

    fetchGrowth(id).then(setGrowth).catch(() => {});
    fetchDailyQuota(id).then(setQuota).catch(() => {});
    fetchStudentStats(id).then(setStats).catch(() => {});
    fetchAchievements(id).then((a) => setBadges(a.badges)).catch(() => {});
    fetchCondition(id).then(setCondition).catch(() => {});
    fetchTestResults(id).then(setTests).catch(() => {});
  }, [id]);

  if (denied) {
    return (
      <div className="page">
        <header className="page-header">
          <button className="btn-back" onClick={() => navigate("/parent")}>← もどる</button>
        </header>
        <p>このお子さんの様子は見られません。</p>
      </div>
    );
  }

  const earned = badges.filter((b) => b.earned);

  return (
    <div className="page">
      <header className="page-header">
        <button className="btn-back" onClick={() => navigate("/parent")}>← もどる</button>
      </header>

      <h2 style={{ fontSize: "1.3rem", fontWeight: 700, marginBottom: "1.25rem" }}>
        {child?.name ?? ""} さんの様子
      </h2>

      {quota && (
        <div className="setup-card" style={{ marginBottom: "1rem" }}>
          <h3 className="parent-section-title">今日のようす</h3>
          <p className="parent-line">
            今日の学習: <b>{quota.earned_points}pt</b>
            {quota.target_points > 0 && <span className="parent-sub">（目安 {quota.target_points}pt）</span>}
          </p>
          <p className="parent-line">学習した日の連続: <b>{quota.streak}日</b></p>
          <p className="parent-line">ノルマ達成の連続: <b>{quota.quota_streak}日</b></p>
          {condition && condition.idle_days > 0 && (
            <p className="parent-line parent-sub">最後の学習から {condition.idle_days}日 たっています</p>
          )}
        </div>
      )}

      {growth && growth.labels_actual.length > 0 && (
        <div className="setup-card" style={{ marginBottom: "1rem" }}>
          <h3 className="parent-section-title">成長のようす</h3>
          <GrowthChart growth={growth} />
        </div>
      )}

      {stats.length > 0 && (
        <div className="setup-card" style={{ marginBottom: "1rem" }}>
          <h3 className="parent-section-title">学力の内わけ</h3>
          {stats.map((s) => (
            <p key={s.stat_type_id} className="parent-line">
              {s.name}: <b>{s.value}pt</b>
              {s.goal && <span className="parent-sub">（目標 {s.goal.target_value}pt / {s.goal.target_date}）</span>}
            </p>
          ))}
        </div>
      )}

      {tests.length > 0 && (
        <div className="setup-card" style={{ marginBottom: "1rem" }}>
          <h3 className="parent-section-title">テストの結果（新しい順に5件）</h3>
          {tests.slice(0, 5).map((t) => (
            <p key={t.id} className="parent-line">
              {t.scope_label}: <b>{t.score_percent}点</b>
              <span className="parent-sub">（{t.correct_count}/{t.total_questions}問・{new Date(t.created_at).toLocaleDateString("ja-JP")}）</span>
            </p>
          ))}
        </div>
      )}

      {earned.length > 0 && (
        <div className="setup-card" style={{ marginBottom: "1rem" }}>
          <h3 className="parent-section-title">とれた実績（{earned.length}／{badges.length}）</h3>
          <div className="parent-badges">
            {earned.map((b) => (
              <span key={b.key} className="parent-badge">{b.emoji} {b.label}</span>
            ))}
          </div>
        </div>
      )}

      <p style={{ color: "#a0aec0", fontSize: "0.78rem", marginTop: "1rem", lineHeight: 1.7 }}>
        「先生に聞く」でのやりとりの中身は保存していないため、見ることはできません。
      </p>
    </div>
  );
}
