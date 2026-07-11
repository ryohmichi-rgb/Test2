import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { createStudent } from "../api";

export default function StartPage() {
  const [name, setName] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const navigate = useNavigate();

  const handleStart = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;
    setLoading(true);
    setError("");
    try {
      const student = await createStudent(name.trim());
      localStorage.setItem("studentId", String(student.id));
      localStorage.setItem("studentName", student.name);
      navigate("/home");
    } catch {
      setError("エラーが発生しました。もう一度お試しください。");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="start-page">
      <div className="start-card">
        <h1 className="app-title">まなびの広場</h1>
        <p className="app-subtitle">小6・中1 算数・数学 学習サービス</p>
        <form onSubmit={handleStart} className="start-form">
          <label htmlFor="name">あなたのなまえを入力してください</label>
          <input
            id="name"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="例：田中 太郎"
            maxLength={20}
            autoFocus
          />
          {error && <p className="error-text">{error}</p>}
          <button type="submit" disabled={loading || !name.trim()} className="btn-primary">
            {loading ? "読み込み中..." : "はじめる"}
          </button>
        </form>
      </div>
    </div>
  );
}
