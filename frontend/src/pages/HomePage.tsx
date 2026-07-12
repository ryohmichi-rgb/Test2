import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { fetchGrowth, fetchReviewList } from "../api";
import type { Growth } from "../types";
import GrowthChart from "../components/GrowthChart";

type MenuItem = {
  label: string;
  desc: string;
  emoji: string;
  path: string;
  color: string;
  primary?: boolean;
};

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
  const [reviewCount, setReviewCount] = useState(0);

  useEffect(() => {
    if (!studentId) { navigate("/"); return; }
    const id = Number(studentId);
    fetchGrowth(id).then(setGrowth).catch(() => {});
    fetchReviewList(id).then((r) => setReviewCount(r.count)).catch(() => {});
  }, [studentId, navigate]);

  // 成長曲線は活動データ（2点以上）があるときだけ表示
  const showGrowth = growth && growth.total.length >= 2;

  return (
    <div className="page">
      <header style={{ marginBottom: "1.75rem" }}>
        <h1 className="app-title" style={{ fontSize: "1.6rem", textAlign: "left", marginBottom: "0.25rem" }}>
          まなびの広場
        </h1>
        <p style={{ color: "#718096", fontSize: "0.95rem" }}>{studentName}さん、今日は何をする？</p>
      </header>

      {showGrowth && (
        <div style={{ background: "#fff", borderRadius: 14, padding: "1.1rem 1.25rem", boxShadow: "0 2px 8px rgba(0,0,0,0.06)", marginBottom: "1.25rem" }}>
          <GrowthChart growth={growth} />
        </div>
      )}

      <div className="home-grid">
        {MENU.map((item) => (
          <button
            key={item.path}
            className="home-tile"
            onClick={() => navigate(item.path)}
            style={{ borderColor: item.primary ? item.color : "transparent" }}
          >
            <span className="home-tile-emoji" style={{ background: `${item.color}18` }}>{item.emoji}</span>
            <span className="home-tile-text">
              <span className="home-tile-label" style={{ color: item.color }}>{item.label}</span>
              <span className="home-tile-desc">{item.desc}</span>
            </span>
          </button>
        ))}

        {reviewCount > 0 && (
          <button
            className="home-tile"
            onClick={() => navigate("/review")}
            style={{ borderColor: "#e53e3e", gridColumn: "1 / -1" }}
          >
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
