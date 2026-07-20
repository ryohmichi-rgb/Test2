import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { fetchAdminProblems, createAdminProblem, updateAdminProblem, deleteAdminProblem } from "../../api";
import type { AdminProblem, AdminChoice } from "../../types";
import { useAdminGuard } from "./guard";

type Draft = Partial<AdminProblem> & { choices?: AdminChoice[] };

export default function AdminProblemsPage() {
  useAdminGuard();
  const navigate = useNavigate();
  const { unitId } = useParams<{ unitId: string }>();
  const uid = Number(unitId);

  const [problems, setProblems] = useState<AdminProblem[]>([]);
  const [loading, setLoading] = useState(true);
  const [draft, setDraft] = useState<Draft | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const reload = () => fetchAdminProblems(uid).then(setProblems);
  useEffect(() => { reload().finally(() => setLoading(false)); /* eslint-disable-next-line */ }, [uid]);

  const startNew = () => setDraft({ unit_id: uid, question: "", answer: "", hint: "", difficulty: 1, problem_type: "fill_in", active: true, choices: [] });
  const startEdit = (p: AdminProblem) => setDraft({ ...p, choices: p.choices.map((c) => ({ ...c })) });

  const setChoice = (i: number, patch: Partial<AdminChoice>) => {
    const choices = [...(draft!.choices ?? [])]; choices[i] = { ...choices[i], ...patch }; setDraft({ ...draft!, choices });
  };
  const addChoice = () => setDraft({ ...draft!, choices: [...(draft!.choices ?? []), { text: "", is_correct: false }] });
  const removeChoice = (i: number) => setDraft({ ...draft!, choices: (draft!.choices ?? []).filter((_, k) => k !== i) });

  const save = async () => {
    if (!draft?.question?.trim() || !draft.answer?.trim()) { setError("問題文と答えは必須です"); return; }
    setSaving(true); setError("");
    const body = { unit_id: uid, question: draft.question, answer: draft.answer, hint: draft.hint, difficulty: draft.difficulty, problem_type: draft.problem_type, active: draft.active };
    const choices = draft.problem_type === "multiple_choice" ? (draft.choices ?? []) : [];
    try {
      if (draft.id) await updateAdminProblem(draft.id, body, choices);
      else await createAdminProblem(body, choices);
      await reload(); setDraft(null);
    } catch (e: unknown) {
      setError((e as { response?: { data?: { errors?: string[] } } }).response?.data?.errors?.join("・") || "保存に失敗しました");
    } finally { setSaving(false); }
  };

  const toggleActive = async (p: AdminProblem) => { await updateAdminProblem(p.id, { unit_id: uid, active: !p.active }, p.choices); reload(); };
  const remove = async (p: AdminProblem) => {
    if (!confirm("この問題を削除しますか？")) return;
    try { await deleteAdminProblem(p.id); reload(); }
    catch (e: unknown) { alert((e as { response?: { data?: { error?: string } } }).response?.data?.error || "削除できません"); }
  };

  if (loading) return <div className="loading">読み込み中...</div>;

  return (
    <div className="page">
      <header className="page-header">
        <button className="btn-back" onClick={() => navigate("/admin/units")}>← 単元一覧</button>
        <button className="btn-primary" style={{ padding: "0.45rem 1rem", fontSize: "0.9rem" }} onClick={startNew}>＋ 問題を追加</button>
      </header>
      <h2 style={{ fontSize: "1.3rem", fontWeight: 700, marginBottom: "1rem" }}>問題の管理</h2>

      {draft && (
        <div className="admin-form">
          <h3 style={{ fontWeight: 700, marginBottom: "0.75rem" }}>{draft.id ? "問題を編集" : "新しい問題"}</h3>
          <label className="admin-label">問題文</label>
          <textarea className="admin-input" rows={3} value={draft.question ?? ""} onChange={(e) => setDraft({ ...draft, question: e.target.value })} />
          <label className="admin-label">答え</label>
          <input className="admin-input" value={draft.answer ?? ""} onChange={(e) => setDraft({ ...draft, answer: e.target.value })} />
          <label className="admin-label">ヒント</label>
          <input className="admin-input" value={draft.hint ?? ""} onChange={(e) => setDraft({ ...draft, hint: e.target.value })} />
          <div className="admin-row">
            <div><label className="admin-label">難易度</label>
              <select className="admin-input" value={draft.difficulty} onChange={(e) => setDraft({ ...draft, difficulty: Number(e.target.value) })}>
                {[1, 2, 3].map((d) => <option key={d} value={d}>★{d}</option>)}
              </select></div>
            <div><label className="admin-label">種別</label>
              <select className="admin-input" value={draft.problem_type} onChange={(e) => setDraft({ ...draft, problem_type: e.target.value as AdminProblem["problem_type"] })}>
                <option value="fill_in">記述</option>
                <option value="multiple_choice">選択</option>
              </select></div>
          </div>

          {draft.problem_type === "multiple_choice" && (
            <div style={{ margin: "0.5rem 0" }}>
              <label className="admin-label">選択肢（正解にチェック）</label>
              {(draft.choices ?? []).map((c, i) => (
                <div key={i} style={{ display: "flex", gap: "0.4rem", alignItems: "center", marginBottom: "0.35rem" }}>
                  <input type="checkbox" checked={c.is_correct} onChange={(e) => setChoice(i, { is_correct: e.target.checked })} />
                  <input className="admin-input" style={{ margin: 0 }} value={c.text} onChange={(e) => setChoice(i, { text: e.target.value })} />
                  <button className="admin-btn danger" onClick={() => removeChoice(i)}>×</button>
                </div>
              ))}
              <button className="admin-btn" onClick={addChoice}>＋ 選択肢</button>
            </div>
          )}

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
        {problems.map((p) => (
          <div key={p.id} className="admin-row-card" style={{ opacity: p.active ? 1 : 0.55 }}>
            <div style={{ flex: 1 }}>
              <p style={{ fontSize: "0.9rem" }}>{"★".repeat(p.difficulty)} {p.question}</p>
              <p style={{ fontSize: "0.76rem", color: "#a0aec0" }}>答: {p.answer}・{p.problem_type === "fill_in" ? "記述" : "選択"}{!p.active && "・無効"}{p.used && "・使用中"}</p>
            </div>
            <div style={{ display: "flex", gap: "0.35rem", flexWrap: "wrap", justifyContent: "flex-end" }}>
              <button className="admin-btn" onClick={() => startEdit(p)}>編集</button>
              <button className="admin-btn" onClick={() => toggleActive(p)}>{p.active ? "無効化" : "有効化"}</button>
              {!p.used && <button className="admin-btn danger" onClick={() => remove(p)}>削除</button>}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
