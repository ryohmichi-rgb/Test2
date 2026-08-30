import { useEffect, useState } from "react";
import { useNavigate } from "react-router";
import { fetchGrades, fetchLessonReads } from "../api";
import type { Grade, Unit } from "../types";

// 単元を教科ごとにまとめる。教科の並びは教科IDの順（単元の display_order 任せにしない）。
function groupBySubject(units: Unit[]): [string, Unit[]][] {
  const byId = new Map<number, { name: string; units: Unit[] }>();
  for (const u of [...units].sort((a, b) => a.display_order - b.display_order)) {
    const id = u.subject?.id ?? 0;
    if (!byId.has(id)) byId.set(id, { name: u.subject?.name ?? "", units: [] });
    byId.get(id)!.units.push(u);
  }
  return [...byId.entries()].sort((a, b) => a[0] - b[0]).map(([, v]) => [v.name, v.units]);
}

export default function GradesPage() {
  const [grades, setGrades] = useState<Grade[]>([]);
  const [readUnits, setReadUnits] = useState<Set<number>>(new Set());
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
    fetchLessonReads(Number(studentId))
      .then((ids) => setReadUnits(new Set(ids)))
      .catch(() => {});
  }, [navigate, studentId]);

  if (loading) return <div className="loading">読み込み中...</div>;

  return (
    <div className="page">
      <header className="page-header">
        <button className="btn-back" onClick={() => navigate("/home")}>← ホーム</button>
        <button className="btn-secondary" onClick={() => navigate(`/progress/${studentId}`)}>進捗</button>
      </header>

      <h2 style={{ fontSize: "1.4rem", fontWeight: 700, marginBottom: "0.25rem" }}>{studentName}さんの単元べつ演習</h2>
      <h3 className="section-title">学年を選んでください</h3>
      <div className="grade-grid">
        {grades.map((grade) => (
          <div key={grade.id} className="grade-card">
            <h3 className="grade-name">{grade.name}</h3>
            {groupBySubject(grade.units ?? []).map(([subject, units]) => (
              <div key={subject}>
                {/* 教科の見出しは、その学年に2教科以上あるときだけ出す */}
                {groupBySubject(grade.units ?? []).length > 1 && (
                  <p className="unit-subject">{subject}</p>
                )}
                <ul className="unit-list">
                  {units.map((unit) => (
                    <li key={unit.id}>
                      <button
                        className="unit-btn"
                        onClick={() => navigate(`/units/${unit.id}`)}
                      >
                        <span>{unit.title}</span>
                        {readUnits.has(unit.id) && <span className="read-check" title="学習ずみ">✓</span>}
                      </button>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        ))}
      </div>
    </div>
  );
}
