import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { fetchAdminUnits, fetchAdminMeta, createAdminUnit, updateAdminUnit, deleteAdminUnit } from "../../api";
import type { AdminUnit, AdminMeta } from "../../types";
import { useAdminGuard } from "./guard";

type Draft = Partial<AdminUnit>;

export default function AdminUnitsPage() {
  useAdminGuard();
  const navigate = useNavigate();
  const [units, setUnits] = useState<AdminUnit[]>([]);
  const [meta, setMeta] = useState<AdminMeta | null>(null);
  const [loading, setLoading] = useState(true);
  const [draft, setDraft] = useState<Draft | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const reload = () => fetchAdminUnits().then(setUnits);

  useEffect(() => {
    Promise.all([fetchAdminUnits(), fetchAdminMeta()])
      .then(([u, m]) => { setUnits(u); setMeta(m); })
      .finally(() => setLoading(false));
  }, []);

  const startNew = () => setDraft({
    title: "", description: "", lesson_body: "", display_order: (units.at(-1)?.display_order ?? 0) + 1,
    grade_id: meta?.grades[0]?.id, subject_id: meta?.subjects[0]?.id, stat_type_id: meta?.stat_types[0]?.id ?? null, active: true,
  });
  const startEdit = (u: AdminUnit) => setDraft({ ...u });

  const save = async () => {
    if (!draft?.title?.trim()) { setError("単元名を入力してください"); return; }
    setSaving(true); setError("");
    try {
      if (draft.id) await updateAdminUnit(draft.id, draft);
      else await createAdminUnit(draft);
      await reload();
      setDraft(null);
    } catch (e: unknown) {
      const err = e as { response?: { data?: { errors?: string[] } } };
      setError(err.response?.data?.errors?.join("・") || "保存に失敗しました");
    } finally { setSaving(false); }
  };

  const toggleActive = async (u: AdminUnit) => { await updateAdminUnit(u.id, { active: !u.active }); reload(); };
  const remove = async (u: AdminUnit) => {
    if (!confirm(`「${u.title}」を削除しますか？`)) return;
    try { await deleteAdminUnit(u.id); reload(); }
    catch (e: unknown) { alert((e as { response?: { data?: { error?: string } } }).response?.data?.error || "削除できません"); }
  };

  if (loading || !meta) return <div className="loading">読み込み中...</div>;

  return (
    <div className="page">
      <header className="page-header">
        <button className="btn-back" onClick={() => navigate("/admin")}>← 管理</button>
        <button className="btn-primary" style={{ padding: "0.45rem 1rem", fontSize: "0.9rem" }} onClick={startNew}>＋ 単元を追加</button>
      </header>
      <h2 style={{ fontSize: "1.3rem", fontWeight: 700, marginBottom: "1rem" }}>単元・教材</h2>

      {draft && (
        <div className="admin-form">
          <h3 style={{ fontWeight: 700, marginBottom: "0.75rem" }}>{draft.id ? "単元を編集" : "新しい単元"}</h3>
          <label className="admin-label">単元名</label>
          <input className="admin-input" value={draft.title ?? ""} onChange={(e) => setDraft({ ...draft, title: e.target.value })} />
          <label className="admin-label">説明</label>
          <input className="admin-input" value={draft.description ?? ""} onChange={(e) => setDraft({ ...draft, description: e.target.value })} />
          <label className="admin-label">解説（Markdown）</label>
          <textarea className="admin-input" rows={8} value={draft.lesson_body ?? ""} onChange={(e) => setDraft({ ...draft, lesson_body: e.target.value })} />
          <div className="admin-row">
            <div><label className="admin-label">学年</label>
              <select className="admin-input" value={draft.grade_id} onChange={(e) => setDraft({ ...draft, grade_id: Number(e.target.value) })}>
                {meta.grades.map((g) => <option key={g.id} value={g.id}>{g.name}</option>)}
              </select></div>
            <div><label className="admin-label">教科</label>
              <select className="admin-input" value={draft.subject_id} onChange={(e) => setDraft({ ...draft, subject_id: Number(e.target.value) })}>
                {meta.subjects.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
              </select></div>
          </div>
          <div className="admin-row">
            <div><label className="admin-label">ステータス</label>
              <select className="admin-input" value={draft.stat_type_id ?? ""} onChange={(e) => setDraft({ ...draft, stat_type_id: e.target.value ? Number(e.target.value) : null })}>
                <option value="">（なし）</option>
                {meta.stat_types.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
              </select></div>
            <div><label className="admin-label">表示順</label>
              <input type="number" className="admin-input" value={draft.display_order ?? 1} onChange={(e) => setDraft({ ...draft, display_order: Number(e.target.value) })} /></div>
          </div>
          <label style={{ display: "flex", alignItems: "center", gap: "0.4rem", fontSize: "0.9rem", margin: "0.5rem 0" }}>
            <input type="checkbox" checked={draft.active ?? true} onChange={(e) => setDraft({ ...draft, active: e.target.checked })} /> 有効（オフで出題から除外）
          </label>
          {error && <p className="error-text">{error}</p>}
          <div style={{ display: "flex", gap: "0.5rem", marginTop: "0.5rem" }}>
            <button className="btn-primary" onClick={save} disabled={saving}>{saving ? "保存中..." : "保存"}</button>
            <button className="btn-hint" onClick={() => { setDraft(null); setError(""); }}>キャンセル</button>
          </div>
        </div>
      )}

      <div style={{ display: "flex", flexDirection: "column", gap: "0.6rem" }}>
        {units.map((u) => (
          <div key={u.id} className="admin-row-card" style={{ opacity: u.active ? 1 : 0.55 }}>
            <div style={{ flex: 1 }}>
              <p style={{ fontWeight: 600 }}>{u.title} {!u.active && <span style={{ fontSize: "0.72rem", color: "#e53e3e" }}>（無効）</span>}</p>
              <p style={{ fontSize: "0.76rem", color: "#a0aec0" }}>{u.grade}・{u.stat_type ?? "—"}・問題{u.problem_count}{u.used && "・使用中"}</p>
            </div>
            <div style={{ display: "flex", gap: "0.35rem", flexWrap: "wrap", justifyContent: "flex-end" }}>
              <button className="admin-btn" onClick={() => navigate(`/admin/units/${u.id}/problems`)}>問題</button>
              <button className="admin-btn" onClick={() => startEdit(u)}>編集</button>
              <button className="admin-btn" onClick={() => toggleActive(u)}>{u.active ? "無効化" : "有効化"}</button>
              {!u.used && <button className="admin-btn danger" onClick={() => remove(u)}>削除</button>}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
