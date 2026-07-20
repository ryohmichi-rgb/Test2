import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { fetchGrowth, fetchReviewList, fetchDailyQuota, fetchStudentStats, fetchAchievements } from "../api";
import type { Growth, DailyQuota, StudentStat, Badge } from "../types";
import GrowthChart from "../components/GrowthChart";
import DailyQuotaCard from "../components/DailyQuotaCard";
import MascotMessage from "../components/MascotMessage";
import DailyProblemCard from "../components/DailyProblemCard";
import AchievementsRow from "../components/AchievementsRow";

type MenuItem = { label: string; desc: string; emoji: string; path: string; color: string; primary?: boolean };

const MENU: MenuItem[] = [
  { label: "今日のプラン", desc: "目標から逆算した学習", emoji: "🎯", path: "/plan", color: "#4c51bf", primary: true },
  { label: "単元べつ演習", desc: "単元を選んでじっくり", emoji: "📚", path: "/grades", color: "#38a169" },
  { label: "問題集", desc: "学年の範囲をまとめて練習", emoji: "📖", path: "/problem-set", color: "#dd6b20" },
  { label: "テスト", desc: "実力をためして採点", emoji: "📝", path: "/test", color: "#e53e3e" },
  { label: "ステータス", desc: "今の学力・目標を見る", emoji: "📊", path: "/stats", color: "#805ad5" },
  { label: "テスト履歴", desc: "点数の推移をふり返る", emoji: "📈", path: "/test-history", color: "#319795" },
];

export default function HomePage() {
  const navigate = useNavigate();
  const studentName = localStorage.getItem("studentName") || "";
  const studentId = localStorage.getItem("studentId");

  const [growth, setGrowth] = useState<Growth | null>(null);
  const [quota, setQuota] = useState<DailyQuota | null>(null);
  const [reviewCount, setReviewCount] = useState(0);
  const [stats, setStats] = useState<StudentStat[]>([]);
  const [badges, setBadges] = useState<Badge[]>([]);

  useEffect(() => {
    if (!studentId) { navigate("/"); return; }
    const id = Number(studentId);
    fetchGrowth(id).then(setGrowth).catch(() => {});
    fetchDailyQuota(id).then(setQuota).catch(() => {});
    fetchReviewList(id).then((r) => setReviewCount(r.count)).catch(() => {});
    fetchStudentStats(id).then(setStats).catch(() => {});
    fetchAchievements(id).then(setBadges).catch(() => {});
  }, [studentId, navigate]);

  const logout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("studentId");
    localStorage.removeItem("studentName");
    navigate("/");
  };

  // 一番近い目標（残りポイントが最小の、未達成の目標）
  const nearestGoal = useMemo(() => {
    const withGoal = stats.filter((s) => s.goal && s.value < s.goal.target_value);
    if (withGoal.length === 0) return null;
    return withGoal.reduce((a, b) =>
      (b.goal!.target_value - b.value) < (a.goal!.target_value - a.value) ? b : a
    );
  }, [stats]);

  const showGrowth = growth && (growth.labels_actual.length >= 2 || growth.labels_target.length >= 1);

  return (
    <div className="page">
      <header style={{ marginBottom: "1rem", display: "flex", justifyContent: "space-between", alignItems: "center", gap: "0.75rem" }}>
        <h1 className="app-title" style={{ fontSize: "1.5rem", textAlign: "left", margin: 0 }}>まなびの広場</h1>
        <button className="btn-hint" style={{ fontSize: "0.8rem", flexShrink: 0 }} onClick={logout}>ログアウト</button>
      </header>

      <MascotMessage name={studentName} quota={quota} />

      {quota && <DailyQuotaCard quota={quota} onStart={() => navigate("/plan")} />}

      {nearestGoal && nearestGoal.goal && (
        <div className="goal-distance" onClick={() => navigate("/stats")}>
          🎯 <strong>{nearestGoal.name}</strong> 目標まであと{" "}
          <strong style={{ color: "#4c51bf" }}>{nearestGoal.goal.target_value - nearestGoal.value}pt</strong>
        </div>
      )}

      <DailyProblemCard studentId={Number(studentId)} />

      {showGrowth && (
        <div style={{ background: "#fff", borderRadius: 14, padding: "1.1rem 1.25rem", boxShadow: "0 2px 8px rgba(0,0,0,0.06)", marginBottom: "1.25rem" }}>
          <GrowthChart growth={growth} />
        </div>
      )}

      <AchievementsRow badges={badges} />

      <div className="home-grid">
        {MENU.map((item) => (
          <button key={item.path} className="home-tile" onClick={() => navigate(item.path)} style={{ borderColor: item.primary ? item.color : "transparent" }}>
            <span className="home-tile-emoji" style={{ background: `${item.color}18` }}>{item.emoji}</span>
            <span className="home-tile-text">
              <span className="home-tile-label" style={{ color: item.color }}>{item.label}</span>
              <span className="home-tile-desc">{item.desc}</span>
            </span>
          </button>
        ))}

        {reviewCount > 0 && (
          <button className="home-tile" onClick={() => navigate("/review")} style={{ borderColor: "#e53e3e", gridColumn: "1 / -1" }}>
            <span className="home-tile-emoji" style={{ background: "#e53e3e18" }}>🔁</span>
            <span className="home-tile-text">
              <span className="home-tile-label" style={{ color: "#e53e3e" }}>復習（{reviewCount}問）</span>
              <span className="home-tile-desc">間違えたままの問題をやり直す</span>
            </span>
          </button>
        )}
      </div>
    </div>
  );
}
