import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import ReactMarkdown from "react-markdown";
import { fetchUnit, markLessonRead } from "../api";
import type { Unit } from "../types";

export default function LessonPage() {
  const { unitId } = useParams<{ unitId: string }>();
  const navigate = useNavigate();
  const studentId = Number(localStorage.getItem("studentId"));

  const [unit, setUnit] = useState<Unit | null>(null);
  const [loading, setLoading] = useState(true);
  const [awarded, setAwarded] = useState(0);

  useEffect(() => {
    if (!studentId) { navigate("/"); return; }
    const id = Number(unitId);
    fetchUnit(id)
      .then(setUnit)
      .finally(() => setLoading(false));
    // 初回読了で +5pt（1回きり）
    markLessonRead(studentId, id)
      .then((r) => { if (r.awarded) setAwarded(r.points); })
      .catch(() => {});
  }, [unitId, studentId, navigate]);

  if (loading || !unit) return <div className="loading">読み込み中...</div>;

  return (
    <div className="page">
      <header className="page-header">
        <button className="btn-back" onClick={() => navigate("/grades")}>← 単元一覧</button>
      </header>

      <h2 style={{ fontSize: "1.4rem", fontWeight: 700, marginBottom: "0.25rem" }}>{unit.title}</h2>
      {unit.description && (
        <p style={{ color: "#718096", fontSize: "0.9rem", marginBottom: "1.25rem" }}>{unit.description}</p>
      )}

      <div className="lesson-body">
        {unit.lesson_body
          ? <ReactMarkdown>{unit.lesson_body}</ReactMarkdown>
          : <p style={{ color: "#a0aec0" }}>この単元の解説は準備中です。</p>}
      </div>

      <button className="btn-primary" style={{ width: "100%", marginTop: "1.5rem", padding: "0.9rem" }} onClick={() => navigate(`/units/${unit.id}/practice`)}>
        演習をはじめる →
      </button>

      {awarded > 0 && <div className="toast">はじめての学習！ +{awarded}pt 🎉</div>}
    </div>
  );
}
