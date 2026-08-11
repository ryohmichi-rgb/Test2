import { useEffect, useState } from "react";
import { useNavigate } from "react-router";
import { fetchChildren } from "../api";
import type { Child } from "../types";

// 保護者のホーム。見られる子どもを並べ、選ぶとその子の様子を見にいく。
// 保護者は「見る専用」なので、問題を解く・目標を決めるといった導線は一切置かない。
export default function ParentHomePage() {
  const navigate = useNavigate();
  const parentName = localStorage.getItem("studentName") || "";
  const [children, setChildren] = useState<Child[] | null>(null);

  useEffect(() => {
    fetchChildren().then(setChildren).catch(() => setChildren([]));
  }, []);

  const logout = () => {
    localStorage.clear();
    navigate("/");
  };

  const daysAgo = (date: string | null) => {
    if (!date) return "まだ学習していません";
    const diff = Math.floor((Date.now() - new Date(date).getTime()) / 86400000);
    if (diff <= 0) return "今日学習しました";
    if (diff === 1) return "昨日学習しました";
    return `${diff}日前に学習しました`;
  };

  return (
    <div className="page">
      <header style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem", gap: "0.75rem" }}>
        <h1 className="app-title" style={{ fontSize: "1.5rem", textAlign: "left", margin: 0 }}>まなびの広場</h1>
        <button className="btn-hint" style={{ fontSize: "0.8rem" }} onClick={logout}>ログアウト</button>
      </header>

      <p style={{ color: "#718096", fontSize: "0.9rem", marginBottom: "1.5rem" }}>
        {parentName} さん（保護者）
      </p>

      {children === null ? (
        <div className="loading">読み込み中...</div>
      ) : children.length === 0 ? (
        <div className="setup-card">
          <p style={{ fontSize: "0.95rem", lineHeight: 1.8 }}>
            まだお子さんが登録されていません。<br />
            管理者に紐づけを依頼してください。
          </p>
        </div>
      ) : (
        <div className="grade-grid">
          {children.map((c) => (
            <button
              key={c.id}
              className="grade-card parent-child-card"
              onClick={() => navigate(`/parent/children/${c.id}`)}
            >
              <div className="parent-child-head">
                <span className="parent-child-name">{c.name}</span>
                {c.rank && <span className="parent-child-rank">{c.rank}</span>}
              </div>
              <div className="parent-child-meta">
                <span>{c.total_points}pt</span>
                {c.streak > 0 && <span>🔥 {c.streak}日れんぞく</span>}
              </div>
              <p className="parent-child-last">{daysAgo(c.last_studied_on)}</p>
            </button>
          ))}
        </div>
      )}

      <p style={{ color: "#a0aec0", fontSize: "0.78rem", marginTop: "1.5rem", lineHeight: 1.7 }}>
        保護者アカウントは学習の様子を見ることだけができます。
        問題を解いたり、目標を変えたりはできません。
      </p>
    </div>
  );
}
