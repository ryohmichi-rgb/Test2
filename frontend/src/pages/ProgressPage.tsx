import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { fetchStudentProgress } from "../api";
import type { StudentProgress, UnitProgress } from "../types";

export default function ProgressPage() {
  const { studentId } = useParams<{ studentId: string }>();
  const navigate = useNavigate();
  const [data, setData] = useState<StudentProgress | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStudentProgress(Number(studentId))
      .then(setData)
      .finally(() => setLoading(false));
  }, [studentId]);

  if (loading) return <div className="loading">読み込み中...</div>;
  if (!data) return <div className="loading">データが見つかりません</div>;

  const totalAnswered = data.progress.reduce((s, p) => s + p.answered, 0);
  const totalCorrect = data.progress.reduce((s, p) => s + p.correct, 0);
  const overallAccuracy = totalAnswered > 0 ? Math.round((totalCorrect / totalAnswered) * 100) : 0;

  const byGrade = data.progress.reduce<Record<string, UnitProgress[]>>((acc, p) => {
    if (!acc[p.grade]) acc[p.grade] = [];
    acc[p.grade].push(p);
    return acc;
  }, {});

  return (
    <div className="page">
      <header className="page-header">
        <button className="btn-back" onClick={() => navigate("/grades")}>
          ← 戻る
        </button>
        <h2>{data.student.name}さんの進捗</h2>
      </header>

      <div className="overall-stats">
        <div className="stat-card">
          <span className="stat-value">{totalAnswered}</span>
          <span className="stat-label">回答数</span>
        </div>
        <div className="stat-card">
          <span className="stat-value">{totalCorrect}</span>
          <span className="stat-label">正解数</span>
        </div>
        <div className="stat-card">
          <span className="stat-value">{overallAccuracy}%</span>
          <span className="stat-label">正解率</span>
        </div>
      </div>

      {Object.entries(byGrade).map(([grade, units]) => (
        <div key={grade} className="grade-progress-section">
          <h3 className="grade-section-title">{grade}</h3>
          <div className="unit-progress-list">
            {units.map((u) => (
              <div key={u.unit_id} className="unit-progress-item">
                <div className="unit-progress-header">
                  <span className="unit-progress-title">{u.unit_title}</span>
                  <span className="unit-progress-score">
                    {u.correct}/{u.answered}問正解 ({u.accuracy}%)
                  </span>
                </div>
                <div className="unit-progress-bar-wrap">
                  <div
                    className="unit-progress-bar-fill"
                    style={{ width: `${u.answered > 0 ? u.accuracy : 0}%` }}
                  />
                </div>
                <p className="unit-progress-meta">
                  全{u.total_problems}問中{u.answered}問回答済み
                </p>
              </div>
            ))}
          </div>
        </div>
      ))}

      <button className="btn-primary" style={{ marginTop: "2rem" }} onClick={() => navigate("/grades")}>
        学習を続ける
      </button>
    </div>
  );
}
