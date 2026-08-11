import { useEffect, useState } from "react";
import { useNavigate } from "react-router";
import { fetchAdminStudents, deleteAdminStudent, resetStudentPassword, createAdminAccount, linkGuardianship, unlinkGuardianship } from "../../api";
import type { AdminStudentSummary } from "../../types";
import { useAdminGuard } from "./guard";

export default function AdminStudentsPage() {
  useAdminGuard();
  const navigate = useNavigate();
  const [students, setStudents] = useState<AdminStudentSummary[]>([]);
  const [loading, setLoading] = useState(true);
  // 再発行したパスワードは一度しか出せないので、閉じるまで画面に残す
  const [issued, setIssued] = useState<{ name: string; password: string } | null>(null);

  // 保護者アカウントの新規作成フォーム
  const [newParent, setNewParent] = useState<{ name: string; username: string } | null>(null);
  // 「どの保護者に子どもを足すか」を開いている行
  const [linking, setLinking] = useState<number | null>(null);

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

  const addParent = async () => {
    if (!newParent?.name || !newParent?.username) return;
    try {
      const res = await createAdminAccount(newParent.name, newParent.username, "parent");
      // パスワードは一度きりなので、再発行と同じ場所に出す
      setIssued({ name: res.name, password: res.password });
      setNewParent(null);
      reload();
    } catch (e: unknown) {
      alert((e as { response?: { data?: { error?: string } } }).response?.data?.error || "作れませんでした");
    }
  };

  const link = async (guardianId: number, studentId: number) => {
    try { await linkGuardianship(guardianId, studentId); setLinking(null); reload(); }
    catch (e: unknown) { alert((e as { response?: { data?: { error?: string } } }).response?.data?.error || "紐づけできません"); }
  };

  const unlink = async (guardianId: number, studentId: number, name: string) => {
    if (!confirm(`「${name}」の学習状況を見られないようにしますか？`)) return;
    await unlinkGuardianship(guardianId, studentId);
    reload();
  };

  const kids = students.filter((s) => s.role !== "parent");

  if (loading) return <div className="loading">読み込み中...</div>;

  return (
    <div className="page">
      <header className="page-header">
        <button className="btn-back" onClick={() => navigate("/admin")}>← 管理</button>
      </header>
      <h2 style={{ fontSize: "1.3rem", fontWeight: 700, marginBottom: "0.35rem" }}>生徒</h2>
      <p style={{ color: "#718096", fontSize: "0.85rem", marginBottom: "1rem" }}>
        登録 {students.length}人（生徒 {kids.length}人 / 保護者 {students.length - kids.length}人）
      </p>

      {/* 保護者アカウントは自分では作れない（新規登録は生徒のみ）。ここから作る */}
      {newParent ? (
        <div className="setup-card" style={{ marginBottom: "1rem" }}>
          <div className="start-form">
            <label>保護者の名前</label>
            <input value={newParent.name} onChange={(e) => setNewParent({ ...newParent, name: e.target.value })} placeholder="例：田中 花子" />
            <label>ログインID（半角英数字）</label>
            <input value={newParent.username} onChange={(e) => setNewParent({ ...newParent, username: e.target.value })} placeholder="例：tanaka_mom" />
            <div style={{ display: "flex", gap: "0.5rem" }}>
              <button className="btn-primary" style={{ flex: 1 }} onClick={addParent}>作る</button>
              <button className="btn-hint" onClick={() => setNewParent(null)}>やめる</button>
            </div>
          </div>
        </div>
      ) : (
        <button className="btn-secondary" style={{ width: "100%", marginBottom: "1rem" }} onClick={() => setNewParent({ name: "", username: "" })}>
          ＋ 保護者アカウントを作る
        </button>
      )}

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
              <p style={{ fontWeight: 600 }}>
                {s.name}
                {s.role === "parent" && <span className="role-tag role-parent">保護者</span>}
                {s.admin && <span className="role-tag">管理者</span>}
              </p>
              <p style={{ fontSize: "0.76rem", color: "#a0aec0" }}>
                ID: {s.username}
                {s.role !== "parent" && <>・正解 {s.correct_count}問・
                  {s.last_studied_on ? `最終学習 ${new Date(s.last_studied_on).toLocaleDateString("ja-JP")}` : "未学習"}</>}
              </p>

              {/* 保護者なら見ている子ども、生徒なら見ている保護者 */}
              {s.role === "parent" ? (
                <div className="link-list">
                  {s.children.map((c) => (
                    <span key={c.id} className="link-chip">
                      {c.name}
                      <button className="link-x" onClick={() => unlink(s.id, c.id, c.name)} aria-label={`${c.name}の紐づけを外す`}>×</button>
                    </span>
                  ))}
                  {linking === s.id ? (
                    <select
                      className="link-select"
                      defaultValue=""
                      onChange={(e) => e.target.value && link(s.id, Number(e.target.value))}
                    >
                      <option value="">子どもを選ぶ…</option>
                      {kids.filter((k) => !s.children.some((c) => c.id === k.id)).map((k) => (
                        <option key={k.id} value={k.id}>{k.name}</option>
                      ))}
                    </select>
                  ) : (
                    <button className="link-chip link-add" onClick={() => setLinking(s.id)}>＋ 子どもを追加</button>
                  )}
                </div>
              ) : s.guardians.length > 0 ? (
                <p style={{ fontSize: "0.72rem", color: "#a0aec0", marginTop: "0.2rem" }}>
                  見ている保護者: {s.guardians.map((g) => g.name).join("、")}
                </p>
              ) : null}
            </div>
            <button className="admin-btn" onClick={() => resetPassword(s)}>パスワード再発行</button>
            {!s.admin && <button className="admin-btn danger" onClick={() => remove(s)}>削除</button>}
          </div>
        ))}
      </div>
    </div>
  );
}
