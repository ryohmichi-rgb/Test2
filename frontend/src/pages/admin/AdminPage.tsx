import { useNavigate } from "react-router-dom";
import { useAdminGuard } from "./guard";

const ITEMS = [
  { label: "単元・教材", desc: "単元/解説の編集、問題の管理", emoji: "📚", path: "/admin/units", color: "#38a169" },
  { label: "参考ステータス", desc: "目標の目安（人物・進路）", emoji: "🎯", path: "/admin/reference", color: "#4c51bf" },
  { label: "生徒", desc: "登録生徒の一覧・状況", emoji: "👥", path: "/admin/students", color: "#805ad5" },
];

export default function AdminPage() {
  useAdminGuard();
  const navigate = useNavigate();

  return (
    <div className="page">
      <header className="page-header">
        <button className="btn-back" onClick={() => navigate("/home")}>← ホーム</button>
      </header>
      <h2 style={{ fontSize: "1.4rem", fontWeight: 700, marginBottom: "0.25rem" }}>管理ページ</h2>
      <p style={{ color: "#718096", fontSize: "0.9rem", marginBottom: "1.5rem" }}>コンテンツと生徒の管理</p>

      <div className="home-grid">
        {ITEMS.map((it) => (
          <button key={it.path} className="home-tile" onClick={() => navigate(it.path)} style={{ borderColor: it.color }}>
            <span className="home-tile-emoji" style={{ background: `${it.color}18` }}>{it.emoji}</span>
            <span className="home-tile-text">
              <span className="home-tile-label" style={{ color: it.color }}>{it.label}</span>
              <span className="home-tile-desc">{it.desc}</span>
            </span>
          </button>
        ))}
      </div>
    </div>
  );
}
