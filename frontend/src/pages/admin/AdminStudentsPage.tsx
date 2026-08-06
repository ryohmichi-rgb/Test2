import { useEffect, useState } from "react";
import { useNavigate } from "react-router";
import { fetchAdminStudents, deleteAdminStudent, resetStudentPassword } from "../../api";
import type { AdminStudentSummary } from "../../types";
import { useAdminGuard } from "./guard";

export default function AdminStudentsPage() {
  useAdminGuard();
  const navigate = useNavigate();
  const [students, setStudents] = useState<AdminStudentSummary[]>([]);
  const [loading, setLoading] = useState(true);
  // 再発行したパスワードは一度しか出せないので、閉じるまで画面に残す
  const [issued, setIssued] = useState<{ name: string; password: string } | null>(null);

  const reload = () => fetchAdminStudents().then(setStudents);
  useEffect(() => { reload().finally(() => setLoading(false)); }, []);

  const remove = async (s: AdminStudentSummary) => {
    if (!confirm(`「${s.name}」を削除しますか？（学習データもすべて消えます）`)) return;
    try { await deleteAdminStudent(s.id); reload(); }
    catch (e: unknown) { alert((e as { response?: { data?: { error?: string } } }).response?.data?.error || "削除できません"); }
  };

  const resetPassword = async (s: AdminStudentSummary) => {
    if (!confirm(`「${s.name}」のパスワードを再発行しますか？\n（いまのパスワードは使えなくなり、ログイン中なら一度ログアウトされます）`)) return;
    try {
      const res = await resetStudentPassword(s.id);
      setIssued({ name: s.name, password: res.password });
    } catch {
      alert("再発行できませんでした");
    }
  };

  if (loading) return <div className="loading">読み込み中...</div>;

  return (
    <div className="page">
      <header className="page-header">
        <button className="btn-back" onClick={() => navigate("/admin")}>← 管理</button>
      </header>
      <h2 style={{ fontSize: "1.3rem", fontWeight: 700, marginBottom: "0.35rem" }}>生徒</h2>
      <p style={{ color: "#718096", fontSize: "0.85rem", marginBottom: "1rem" }}>登録 {students.length}人</p>

      {issued && (
        <div className="issued-password">
          <p className="issued-password-title">{issued.name} さんの あたらしいパスワード</p>
          <p className="issued-password-value">{issued.password}</p>
          <p className="issued-password-note">
            この画面を閉じると二度と表示できません。本人に伝えてから閉じてください。
          </p>
          <button className="btn-primary" style={{ padding: "0.45rem 1.1rem", fontSize: "0.88rem" }} onClick={() => setIssued(null)}>
            伝えました（閉じる）
          </button>
        </div>
      )}

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
            <button className="admin-btn" onClick={() => resetPassword(s)}>パスワード再発行</button>
            {!s.admin && <button className="admin-btn danger" onClick={() => remove(s)}>削除</button>}
          </div>
        ))}
      </div>
    </div>
  );
}
