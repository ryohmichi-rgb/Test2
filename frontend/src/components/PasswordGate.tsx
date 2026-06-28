import { useState } from "react";

const PASSWORD = "611448";
const STORAGE_KEY = "dev_auth";

export default function PasswordGate({ children }: { children: React.ReactNode }) {
  const [authed, setAuthed] = useState(() => localStorage.getItem(STORAGE_KEY) === "1");
  const [input, setInput] = useState("");
  const [error, setError] = useState(false);

  if (authed) return <>{children}</>;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (input === PASSWORD) {
      localStorage.setItem(STORAGE_KEY, "1");
      setAuthed(true);
    } else {
      setError(true);
      setInput("");
    }
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", height: "100vh", gap: 16 }}>
      <p style={{ fontSize: 18 }}>開発中のサービスです</p>
      <form onSubmit={handleSubmit} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 12 }}>
        <input
          type="password"
          value={input}
          onChange={(e) => { setInput(e.target.value); setError(false); }}
          placeholder="パスワード"
          autoFocus
          style={{ fontSize: 18, padding: "8px 12px", borderRadius: 6, border: "1px solid #ccc", width: 200 }}
        />
        {error && <p style={{ color: "red", margin: 0 }}>パスワードが違います</p>}
        <button type="submit" style={{ padding: "8px 24px", fontSize: 16, borderRadius: 6, cursor: "pointer" }}>入る</button>
      </form>
    </div>
  );
}
