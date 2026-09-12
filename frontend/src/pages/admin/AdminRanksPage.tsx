import { useEffect, useState } from "react";
import { useNavigate } from "react-router";
import { fetchAdminRanks, createAdminRank, updateAdminRank, deleteAdminRank } from "../../api";
import type { AdminRank } from "../../types";
import { useAdminGuard } from "./guard";

export default function AdminRanksPage() {
  useAdminGuard();
  const navigate = useNavigate();
  const [ranks, setRanks] = useState<AdminRank[]>([]);
  const [loading, setLoading] = useState(true);
  const [draft, setDraft] = useState<Partial<AdminRank> | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const reload = () => fetchAdminRanks().then(setRanks);
  useEffect(() => { reload().finally(() => setLoading(false)); }, []);

  const save = async () => {
    if (!draft?.name?.trim()) { setError("段位の名前を入力してください"); return; }
    setSaving(true); setError("");
    const payload = {
      name: draft.name,
      threshold_points: Number(draft.threshold_points ?? 0),
      exam_question_count: Number(draft.exam_question_count ?? 10),
      pass_percent: Number(draft.pass_percent ?? 80),
    };
    try {
      if (draft.id) await updateAdminRank(draft.id, payload);
      else await createAdminRank(payload);
      await reload();
      setDraft(null);
    } catch (e: unknown) {
      const err = e as { response?: { data?: { errors?: string[] } } };
      setError(err.response?.data?.errors?.join("・") || "保存に失敗しました");
    } finally { setSaving(false); }
  };

  const remove = async (r: AdminRank) => {
    if (!confirm(`「${r.name}」を削除しますか？`)) return;
    try { await deleteAdminRank(r.id); reload(); }
    catch (e: unknown) { alert((e as { response?: { data?: { error?: string } } }).response?.data?.error || "削除できません"); }
  };

  if (loading) return <div className="loading">読み込み中...</div>;

  return (
    <div className="page">
      <header className="page-header">
        <button className="btn-back" onClick={() => navigate("/admin")}>← 管理</button>
        <button
          className="btn-primary"
          style={{ padding: "0.45rem 1rem", fontSize: "0.9rem" }}
          onClick={() => setDraft({ name: "", threshold_points: (ranks.at(-1)?.threshold_points ?? 0) + 500, exam_question_count: 10, pass_percent: 80 })}
        >
          ＋ 段位を追加
        </button>
      </header>
      <h2 style={{ fontSize: "1.3rem", fontWeight: 700, marginBottom: "0.25rem" }}>ランク</h2>
      <p style={{ color: "#718096", fontSize: "0.9rem", marginBottom: "1.25rem" }}>
        到達ポイント・昇格試験の問題数・合格ラインを調整します。しきい値は下の段位から順に
        大きくなっている必要があります。新しい段位は一番上に足されます。
      </p>

      {draft && (
        <div className="admin-form">
          <h3 style={{ fontWeight: 700, marginBottom: "0.75rem" }}>{draft.id ? "段位を編集" : "新しい段位"}</h3>
          <label className="admin-label">名前</label>
          <input className="admin-input" value={draft.name ?? ""} placeholder="例: 二段"
                 onChange={(e) => setDraft({ ...draft, name: e.target.value })} />
          {draft.id && (draft.badges?.length ?? 0) > 0 && (
            <p className="error-text" style={{ fontSize: "0.78rem" }}>
              ⚠ この名前はバッジ（{draft.badges?.join("・")}）が見ています。
              名前を変えると、そのバッジが取れなくなります。
            </p>
          )}
          <div className="admin-row">
            <div><label className="admin-label">到達ポイント</label>
              <input type="number" className="admin-input" value={draft.threshold_points ?? 0}
                     onChange={(e) => setDraft({ ...draft, threshold_points: Number(e.target.value) })} /></div>
            <div><label className="admin-label">試験の問題数</label>
              <input type="number" className="admin-input" value={draft.exam_question_count ?? 10}
                     onChange={(e) => setDraft({ ...draft, exam_question_count: Number(e.target.value) })} /></div>
          </div>
          <label className="admin-label">合格ライン（％）</label>
          <input type="number" className="admin-input" value={draft.pass_percent ?? 80}
                 onChange={(e) => setDraft({ ...draft, pass_percent: Number(e.target.value) })} />
          {error && <p className="error-text">{error}</p>}
          <div style={{ display: "flex", gap: "0.5rem", marginTop: "0.5rem" }}>
            <button className="btn-primary" onClick={save} disabled={saving}>{saving ? "保存中..." : "保存"}</button>
            <button className="btn-hint" onClick={() => { setDraft(null); setError(""); }}>キャンセル</button>
          </div>
        </div>
      )}

      <div style={{ display: "flex", flexDirection: "column", gap: "0.6rem" }}>
        {ranks.map((r) => (
          <div key={r.id} className="admin-row-card">
            <div style={{ flex: 1 }}>
              <p style={{ fontWeight: 600 }}>
                {r.name}
                {r.badges.length > 0 && <span title="バッジが名前を見ています" style={{ marginLeft: "0.35rem" }}>🏅</span>}
              </p>
              <p style={{ fontSize: "0.76rem", color: "#a0aec0" }}>
                {r.threshold_points}pt・{r.exam_question_count}問・{r.pass_percent}%で合格
                {r.student_count > 0 && `・${r.student_count}人`}
              </p>
            </div>
            <div style={{ display: "flex", gap: "0.35rem" }}>
              <button className="admin-btn" onClick={() => { setDraft({ ...r }); setError(""); }}>編集</button>
              {!r.used && <button className="admin-btn danger" onClick={() => remove(r)}>削除</button>}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
