import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { fetchGrades } from "../api";
import type { Grade } from "../types";

export default function GradesPage() {
  const [grades, setGrades] = useState<Grade[]>([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  const studentName = localStorage.getItem("studentName") || "";
  const studentId = localStorage.getItem("studentId");

  useEffect(() => {
    if (!studentId) {
      navigate("/");
      return;
    }
    fetchGrades()
      .then(setGrades)
      .finally(() => setLoading(false));
  }, [navigate, studentId]);

  if (loading) return <div className="loading">読み込み中...</div>;

  return (
    <div className="page">
      <header className="page-header">
        <h2>{studentName}さんの学習</h2>
        <div style={{ display: "flex", gap: "0.5rem" }}>
          <button className="btn-secondary" onClick={() => navigate("/stats")}>
            ステータス
          </button>
          <button className="btn-secondary" onClick={() => navigate(`/progress/${studentId}`)}>
            進捗
          </button>
        </div>
      </header>

      <h3 className="section-title">学年を選んでください</h3>
      <div className="grade-grid">
        {grades.map((grade) => (
          <div key={grade.id} className="grade-card">
            <h3 className="grade-name">{grade.name}</h3>
            <ul className="unit-list">
              {grade.units
                ?.sort((a, b) => a.display_order - b.display_order)
                .map((unit) => (
                  <li key={unit.id}>
                    <button
                      className="unit-btn"
                      onClick={() => navigate(`/units/${unit.id}`)}
                    >
                      {unit.title}
                    </button>
                  </li>
                ))}
            </ul>
          </div>
        ))}
      </div>
    </div>
  );
}
