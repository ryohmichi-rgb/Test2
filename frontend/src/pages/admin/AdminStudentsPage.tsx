import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { fetchAdminStudents, deleteAdminStudent } from "../../api";
import type { AdminStudentSummary } from "../../types";
import { useAdminGuard } from "./guard";

export default function AdminStudentsPage() {
  useAdminGuard();
  const navigate = useNavigate();
  const [students, setStudents] = useState<AdminStudentSummary[]>([]);
  const [loading, setLoading] = useState(true);

  const reload = () => fetchAdminStudents().then(setStudents);
  useEffect(() => { reload().finally(() => setLoading(false)); }, []);

  const remove = async (s: AdminStudentSummary) => {
    if (!confirm(`「${s.name}」を削除しますか？（学習データもすべて消えます）`)) return;
    try { await deleteAdminStudent(s.id); reload(); }
    catch (e: unknown) { alert((e as { response?: { data?: { error?: string } } }).response?.data?.error || "削除できません"); }
  };

  if (loading) return <div className="loading">読み込み中...</div>;

  return (
    <div className="page">
      <header className="page-header">
        <button className="btn-back" onClick={() => navigate("/admin")}>← 管理</button>
      </header>
      <h2 style={{ fontSize: "1.3rem", fontWeight: 700, marginBottom: "0.35rem" }}>生徒</h2>
      <p style={{ color: "#718096", fontSize: "0.85rem", marginBottom: "1rem" }}>登録 {students.length}人</p>

      <div style={{ display: "flex", flexDirection: "column", gap: "0.6rem" }}>
        {students.map((s) => (
          <div key={s.id} className="admin-row-card">
            <div style={{ flex: 1 }}>
              <p style={{ fontWeight: 600 }}>{s.name} {s.admin && <span style={{ fontSize: "0.7rem", color: "#4c51bf", fontWeight: 700 }}>管理者</span>}</p>
              <p style={{ fontSize: "0.76rem", color: "#a0aec0" }}>
                ID: {s.username}・正解 {s.correct_count}問・
                {s.last_studied_on ? `最終学習 ${new Date(s.last_studied_on).toLocaleDateString("ja-JP")}` : "未学習"}
              </p>
            </div>
            {!s.admin && <button className="admin-btn danger" onClick={() => remove(s)}>削除</button>}
          </div>
        ))}
      </div>
    </div>
  );
}
