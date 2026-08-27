import { useEffect, useState } from "react";
import { useNavigate } from "react-router";
import { fetchAdminSubjects, createAdminSubject, updateAdminSubject, deleteAdminSubject } from "../../api";
import type { AdminSubject } from "../../types";
import { useAdminGuard } from "./guard";

export default function AdminSubjectsPage() {
  useAdminGuard();
  const navigate = useNavigate();
  const [subjects, setSubjects] = useState<AdminSubject[]>([]);
  const [loading, setLoading] = useState(true);
  const [draft, setDraft] = useState<Partial<AdminSubject> | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const reload = () => fetchAdminSubjects().then(setSubjects);
  useEffect(() => { reload().finally(() => setLoading(false)); }, []);

  const save = async () => {
    if (!draft?.name?.trim()) { setError("教科名を入力してください"); return; }
    setSaving(true); setError("");
    try {
      if (draft.id) await updateAdminSubject(draft.id, { name: draft.name });
      else await createAdminSubject({ name: draft.name });
      await reload();
      setDraft(null);
    } catch (e: unknown) {
      const err = e as { response?: { data?: { errors?: string[] } } };
      setError(err.response?.data?.errors?.join("・") || "保存に失敗しました");
    } finally { setSaving(false); }
  };

  const remove = async (s: AdminSubject) => {
    if (!confirm(`「${s.name}」を削除しますか？`)) return;
    try { await deleteAdminSubject(s.id); reload(); }
    catch (e: unknown) { alert((e as { response?: { data?: { error?: string } } }).response?.data?.error || "削除できません"); }
  };

  if (loading) return <div className="loading">読み込み中...</div>;

  return (
    <div className="page">
      <header className="page-header">
        <button className="btn-back" onClick={() => navigate("/admin")}>← 管理</button>
        <button className="btn-primary" style={{ padding: "0.45rem 1rem", fontSize: "0.9rem" }} onClick={() => setDraft({ name: "" })}>＋ 教科を追加</button>
      </header>
      <h2 style={{ fontSize: "1.3rem", fontWeight: 700, marginBottom: "0.25rem" }}>教科</h2>
      <p style={{ color: "#718096", fontSize: "0.9rem", marginBottom: "1.25rem" }}>
        単元をどの教科に入れるかの選択肢になります。単元がぶら下がっている教科は削除できません。
      </p>

      {draft && (
        <div className="admin-form">
          <h3 style={{ fontWeight: 700, marginBottom: "0.75rem" }}>{draft.id ? "教科を編集" : "新しい教科"}</h3>
          <label className="admin-label">教科名</label>
          <input className="admin-input" value={draft.name ?? ""} placeholder="例: 国語"
                 onChange={(e) => setDraft({ ...draft, name: e.target.value })} />
          {error && <p className="error-text">{error}</p>}
          <div style={{ display: "flex", gap: "0.5rem", marginTop: "0.5rem" }}>
            <button className="btn-primary" onClick={save} disabled={saving}>{saving ? "保存中..." : "保存"}</button>
            <button className="btn-hint" onClick={() => { setDraft(null); setError(""); }}>キャンセル</button>
          </div>
        </div>
      )}

      <div style={{ display: "flex", flexDirection: "column", gap: "0.6rem" }}>
        {subjects.map((s) => (
          <div key={s.id} className="admin-row-card">
            <div style={{ flex: 1 }}>
              <p style={{ fontWeight: 600 }}>{s.name}</p>
              <p style={{ fontSize: "0.76rem", color: "#a0aec0" }}>単元{s.unit_count}</p>
            </div>
            <div style={{ display: "flex", gap: "0.35rem" }}>
              <button className="admin-btn" onClick={() => { setDraft({ ...s }); setError(""); }}>編集</button>
              {!s.used && <button className="admin-btn danger" onClick={() => remove(s)}>削除</button>}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
