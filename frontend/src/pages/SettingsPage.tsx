import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { changePassword } from "../api";
import { BGM_RANDOM, BGM_TRACKS, bgmTrack, isBgmOn, setBgmTrack, toggleBgm } from "../sound";

// 生徒が自分でパスワードを変える画面。
// パスワードを変えると今までのトークンは失効するので、返ってきた新しいトークンに差し替える
// （そうしないと本人が締め出される）。
export default function SettingsPage() {
  const navigate = useNavigate();
  const studentId = Number(localStorage.getItem("studentId"));
  const studentName = localStorage.getItem("studentName") || "";

  const [current, setCurrent] = useState("");
  const [next, setNext] = useState("");
  const [confirm, setConfirm] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);

  const [bgmOn, setBgmOnState] = useState(isBgmOn());
  const [track, setTrack] = useState(bgmTrack());

  const chooseTrack = (id: string) => {
    setTrack(id);
    setBgmTrack(id); // オンなら鳴っている曲もすぐ切り替わる
  };

  const submit = async () => {
    setError(null);
    if (next.length < 4) return setError("あたらしいパスワードは4文字以上にしてね");
    if (next !== confirm) return setError("かくにん用のパスワードが一致しません");

    setSaving(true);
    try {
      const res = await changePassword(studentId, current, next);
      localStorage.setItem("token", res.token); // 古いトークンは失効しているので差し替える
      setCurrent(""); setNext(""); setConfirm("");
      setDone(true);
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { error?: string } } }).response?.data?.error;
      setError(msg || "変更できませんでした");
    } finally {
      setSaving(false);
    }
  };

  const logout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("studentId");
    localStorage.removeItem("studentName");
    localStorage.removeItem("admin");
    navigate("/");
  };

  return (
    <div className="page">
      <header className="page-header">
        <button className="btn-back" onClick={() => navigate("/home")}>← ホーム</button>
      </header>

      <h2 style={{ fontSize: "1.3rem", fontWeight: 700, marginBottom: "0.25rem" }}>せってい</h2>
      <p style={{ color: "#718096", fontSize: "0.85rem", marginBottom: "1.25rem" }}>
        {studentName} さん（ログイン中）
      </p>

      <div className="setup-card">
        <h3 style={{ fontSize: "1rem", fontWeight: 700, marginBottom: "0.75rem" }}>パスワードを変える</h3>

        {done ? (
          <>
            <p style={{ color: "#276749", fontSize: "0.95rem", marginBottom: "1rem" }}>
              ✓ あたらしいパスワードに変わりました
            </p>
            <button className="btn-secondary" style={{ width: "100%" }} onClick={() => setDone(false)}>
              もう一度変える
            </button>
          </>
        ) : (
          <div className="start-form">
            <label>いまのパスワード</label>
            <input type="password" value={current} onChange={(e) => setCurrent(e.target.value)} autoComplete="current-password" />

            <label>あたらしいパスワード（4文字以上）</label>
            <input type="password" value={next} onChange={(e) => setNext(e.target.value)} autoComplete="new-password" />

            <label>もういちど入力</label>
            <input
              type="password"
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && submit()}
              autoComplete="new-password"
            />

            {error && <p className="error-text">{error}</p>}

            <button className="btn-primary" onClick={submit} disabled={saving || !current || !next || !confirm}>
              {saving ? "..." : "変える"}
            </button>
          </div>
        )}
      </div>

      <p style={{ color: "#a0aec0", fontSize: "0.78rem", margin: "1rem 0 1.5rem", lineHeight: 1.6 }}>
        パスワードを忘れてしまったときは、管理者に再発行してもらってください。
      </p>

      <div className="setup-card">
        <h3 style={{ fontSize: "1rem", fontWeight: 700, marginBottom: "0.75rem" }}>BGM</h3>

        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: "0.75rem" }}>
          <span style={{ fontSize: "0.95rem" }}>音楽を流す</span>
          <button className="btn-hint" onClick={() => setBgmOnState(toggleBgm())}>
            {bgmOn ? "🎵 オン" : "🔇 オフ"}
          </button>
        </div>

        {/* 曲が1つしかないうちは選ぶものがないので出さない */}
        {BGM_TRACKS.length > 1 && (
          <div className="start-form" style={{ marginTop: "1rem" }}>
            <label>曲</label>
            <select value={track} onChange={(e) => chooseTrack(e.target.value)}>
              <option value={BGM_RANDOM}>ランダム（おまかせ）</option>
              {BGM_TRACKS.map((t) => (
                <option key={t.id} value={t.id}>{t.label}</option>
              ))}
            </select>
            <p style={{ color: "#a0aec0", fontSize: "0.78rem", margin: "0.5rem 0 0", lineHeight: 1.6 }}>
              「ランダム」だと、1曲おわるたびにちがう曲になります。
            </p>
          </div>
        )}
      </div>

      <button className="btn-hint" style={{ width: "100%" }} onClick={logout}>ログアウト</button>
    </div>
  );
}
