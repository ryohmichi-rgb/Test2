import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { login, signup } from "../api";
import type { AuthResult } from "../types";

type Mode = "login" | "signup";

export default function AuthPage() {
  const navigate = useNavigate();
  const [mode, setMode] = useState<Mode>("login");
  const [name, setName] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const onSuccess = (res: AuthResult) => {
    localStorage.setItem("token", res.token);
    localStorage.setItem("studentId", String(res.student.id));
    localStorage.setItem("studentName", res.student.name);
    // 新規登録、または未オンボーディングならウィザードへ
    if (mode === "signup" || !res.student.onboarded) navigate("/onboarding");
    else navigate("/home");
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (loading) return;
    setLoading(true);
    setError("");
    try {
      const res = mode === "login"
        ? await login(username.trim(), password)
        : await signup(name.trim(), username.trim(), password);
      onSuccess(res);
    } catch (err: unknown) {
      const e = err as { response?: { data?: { error?: string; errors?: string[] } } };
      setError(e.response?.data?.error || e.response?.data?.errors?.join("・") || "うまくいきませんでした。もう一度お試しください。");
    } finally {
      setLoading(false);
    }
  };

  const canSubmit = username.trim() && password && (mode === "login" || name.trim());

  return (
    <div className="start-page">
      <div className="start-card">
        <h1 className="app-title">まなびの広場</h1>
        <p className="app-subtitle">小6・中1 算数・数学 学習サービス</p>

        <div className="chip-row" style={{ justifyContent: "center", marginBottom: "1.25rem" }}>
          <button className={`chip ${mode === "login" ? "chip-on" : ""}`} onClick={() => { setMode("login"); setError(""); }}>ログイン</button>
          <button className={`chip ${mode === "signup" ? "chip-on" : ""}`} onClick={() => { setMode("signup"); setError(""); }}>新規登録</button>
        </div>

        <form onSubmit={handleSubmit} className="start-form">
          {mode === "signup" && (
            <>
              <label htmlFor="name">なまえ</label>
              <input id="name" type="text" value={name} onChange={(e) => setName(e.target.value)} placeholder="例：田中 太郎" maxLength={20} autoFocus />
            </>
          )}

          <label htmlFor="username">ユーザーID</label>
          <input id="username" type="text" value={username} onChange={(e) => setUsername(e.target.value)} placeholder="半角英数字" maxLength={30} autoComplete="username" autoFocus={mode === "login"} />

          <label htmlFor="password">パスワード</label>
          <input id="password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="4文字以上" autoComplete={mode === "login" ? "current-password" : "new-password"} />

          {error && <p className="error-text">{error}</p>}

          <button type="submit" disabled={loading || !canSubmit} className="btn-primary">
            {loading ? "..." : mode === "login" ? "ログイン" : "登録してはじめる"}
          </button>
        </form>
      </div>
    </div>
  );
}
