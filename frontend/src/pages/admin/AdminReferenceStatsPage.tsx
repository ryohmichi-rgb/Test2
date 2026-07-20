import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { fetchAdminReferenceStats, fetchAdminMeta, createAdminReferenceStat, updateAdminReferenceStat, deleteAdminReferenceStat } from "../../api";
import type { AdminReferenceStat, AdminMeta } from "../../types";
import { useAdminGuard } from "./guard";

type Draft = Partial<AdminReferenceStat>;

export default function AdminReferenceStatsPage() {
  useAdminGuard();
  const navigate = useNavigate();
  const [refs, setRefs] = useState<AdminReferenceStat[]>([]);
  const [meta, setMeta] = useState<AdminMeta | null>(null);
  const [loading, setLoading] = useState(true);
  const [draft, setDraft] = useState<Draft | null>(null);
  const [saving, setSaving] = useState(false);

  const reload = () => fetchAdminReferenceStats().then(setRefs);
  useEffect(() => {
    Promise.all([fetchAdminReferenceStats(), fetchAdminMeta()]).then(([r, m]) => { setRefs(r); setMeta(m); }).finally(() => setLoading(false));
  }, []);

  const startNew = () => setDraft({ label: "", stat_type_id: meta?.stat_types[0]?.id, value: 100 });
  const save = async () => {
    if (!draft?.label?.trim() || !draft.stat_type_id || !draft.value) return;
    setSaving(true);
    try {
      if (draft.id) await updateAdminReferenceStat(draft.id, draft);
      else await createAdminReferenceStat(draft);
      await reload(); setDraft(null);
    } finally { setSaving(false); }
  };
  const remove = async (r: AdminReferenceStat) => { if (confirm(`${r.label}（${r.stat_type}）を削除？`)) { await deleteAdminReferenceStat(r.id); reload(); } };

  if (loading || !meta) return <div className="loading">読み込み中...</div>;

  // ラベルでグルーピング
  const groups = refs.reduce<Record<string, AdminReferenceStat[]>>((acc, r) => { (acc[r.label] ||= []).push(r); return acc; }, {});

  return (
    <div className="page">
      <header className="page-header">
        <button className="btn-back" onClick={() => navigate("/admin")}>← 管理</button>
        <button className="btn-primary" style={{ padding: "0.45rem 1rem", fontSize: "0.9rem" }} onClick={startNew}>＋ 追加</button>
      </header>
      <h2 style={{ fontSize: "1.3rem", fontWeight: 700, marginBottom: "0.35rem" }}>参考ステータス</h2>
      <p style={{ color: "#718096", fontSize: "0.85rem", marginBottom: "1rem" }}>目標の目安。同じラベルでステータスごとに1行ずつ。</p>

      {draft && (
        <div className="admin-form">
          <label className="admin-label">ラベル（例: 数学の先生）</label>
          <input className="admin-input" value={draft.label ?? ""} onChange={(e) => setDraft({ ...draft, label: e.target.value })} />
          <div className="admin-row">
            <div><label className="admin-label">ステータス</label>
              <select className="admin-input" value={draft.stat_type_id} onChange={(e) => setDraft({ ...draft, stat_type_id: Number(e.target.value) })}>
                {meta.stat_types.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
              </select></div>
            <div><label className="admin-label">値</label>
              <input type="number" className="admin-input" value={draft.value ?? 0} onChange={(e) => setDraft({ ...draft, value: Number(e.target.value) })} /></div>
          </div>
          <div style={{ display: "flex", gap: "0.5rem" }}>
            <button className="btn-primary" onClick={save} disabled={saving}>{saving ? "保存中..." : "保存"}</button>
            <button className="btn-hint" onClick={() => setDraft(null)}>キャンセル</button>
          </div>
        </div>
      )}

      {Object.entries(groups).map(([label, rows]) => (
        <div key={label} style={{ background: "#fff", borderRadius: 12, padding: "1rem 1.25rem", boxShadow: "0 2px 8px rgba(0,0,0,0.06)", marginBottom: "0.75rem" }}>
          <p style={{ fontWeight: 700, marginBottom: "0.5rem" }}>{label}</p>
          {rows.map((r) => (
            <div key={r.id} style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0.25rem 0", fontSize: "0.88rem" }}>
              <span>{r.stat_type}：<strong>{r.value}</strong></span>
              <span style={{ display: "flex", gap: "0.35rem" }}>
                <button className="admin-btn" onClick={() => setDraft({ ...r })}>編集</button>
                <button className="admin-btn danger" onClick={() => remove(r)}>削除</button>
              </span>
            </div>
          ))}
        </div>
      ))}
    </div>
  );
}
