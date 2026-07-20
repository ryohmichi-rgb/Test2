import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { fetchReferenceStats, updateGoal, completeOnboarding, fetchLearningPlan, fetchGrades } from "../api";
import type { ReferenceStat } from "../types";
import Mascot from "../components/Mascot";
import ReferenceIcon from "../components/ReferenceIcon";

// オンボーディングでは選びやすい進路系にしぼる（全部はステータス画面で選べる）
const ONBOARDING_LABELS = ["中学卒業レベル", "高校受験（公立）", "難関高校受験", "数学の先生"];

const defaultGoalDate = () => {
  const d = new Date();
  d.setMonth(d.getMonth() + 3);
  return d.toISOString().slice(0, 10);
};

export default function OnboardingPage() {
  const navigate = useNavigate();
  const studentId = Number(localStorage.getItem("studentId"));
  const studentName = localStorage.getItem("studentName") || "";

  const [step, setStep] = useState(0);
  const [refs, setRefs] = useState<ReferenceStat[]>([]);
  const [saving, setSaving] = useState(false);
  const [chosenLabel, setChosenLabel] = useState<string | null>(null);

  useEffect(() => {
    if (!studentId) { navigate("/"); return; }
    fetchReferenceStats()
      .then((r) => setRefs(
        r.filter((x) => ONBOARDING_LABELS.includes(x.label))
          .sort((a, b) => ONBOARDING_LABELS.indexOf(a.label) - ONBOARDING_LABELS.indexOf(b.label))
      ))
      .catch(() => {});
  }, [studentId, navigate]);

  // オンボーディングを終えてホーム（またはおすすめ教材）へ
  const finish = async (goLesson: boolean) => {
    setSaving(true);
    try {
      await completeOnboarding(studentId).catch(() => {});
      if (goLesson) {
        let unitId: number | undefined;
        try {
          const plan = await fetchLearningPlan(studentId);
          unitId = plan.today_plan[0]?.unit_id;
        } catch { /* ignore */ }
        if (!unitId) {
          try {
            const grades = await fetchGrades();
            unitId = grades[0]?.units?.slice().sort((a, b) => a.display_order - b.display_order)[0]?.id;
          } catch { /* ignore */ }
        }
        navigate(unitId ? `/units/${unitId}` : "/home");
      } else {
        navigate("/home");
      }
    } finally {
      setSaving(false);
    }
  };

  const chooseGoal = async (ref: ReferenceStat) => {
    setSaving(true);
    setChosenLabel(ref.label);
    try {
      const date = defaultGoalDate();
      await Promise.all(ref.stats.map((s) => updateGoal(studentId, s.stat_type_id, s.value, date)));
      setStep(2);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="onboarding">
      <div className="onboarding-card">
        {/* 進捗ドット */}
        <div className="onboarding-dots">
          {[0, 1, 2].map((i) => (
            <span key={i} className={`onboarding-dot ${i <= step ? "on" : ""}`} />
          ))}
        </div>

        {step === 0 && (
          <div className="onboarding-step">
            <Mascot size={96} />
            <h2 className="onboarding-title">ようこそ、{studentName}さん！</h2>
            <p className="onboarding-text">
              「まなびの広場」へようこそ。<br />
              3ステップで学習をはじめよう。<br />
              まずは<strong>目標を決めて</strong>、さっそく1つ学んでみよう！
            </p>
            <button className="btn-primary onboarding-btn" onClick={() => setStep(1)}>はじめる →</button>
            <button className="onboarding-skip" onClick={() => finish(false)}>スキップ</button>
          </div>
        )}

        {step === 1 && (
          <div className="onboarding-step">
            <h2 className="onboarding-title">目標を決めよう</h2>
            <p className="onboarding-text">どこを目指す？ 1つ選んでね（あとで変えられるよ）</p>

            <div className="onboarding-goals">
              {refs.map((ref) => (
                <button
                  key={ref.label}
                  className="onboarding-goal-card"
                  disabled={saving}
                  onClick={() => chooseGoal(ref)}
                >
                  <ReferenceIcon label={ref.label} size={48} />
                  <div style={{ flex: 1, textAlign: "left" }}>
                    <div style={{ fontWeight: 700, color: "#2d3748" }}>{ref.label}</div>
                    <div style={{ fontSize: "0.75rem", color: "#a0aec0" }}>
                      {ref.stats.slice(0, 3).map((s) => `${s.name}${s.value}`).join("・")}
                    </div>
                  </div>
                  <span style={{ color: "#a0aec0", fontSize: "1.2rem" }}>›</span>
                </button>
              ))}
            </div>

            <button className="onboarding-skip" onClick={() => setStep(2)}>あとで決める</button>
          </div>
        )}

        {step === 2 && (
          <div className="onboarding-step">
            <Mascot size={80} />
            <h2 className="onboarding-title">さっそく学ぼう！</h2>
            <p className="onboarding-text">
              {chosenLabel ? `「${chosenLabel}」を目標にしたよ。` : ""}
              まずは1つ目の<strong>解説</strong>を読んで、問題に挑戦してみよう。
            </p>
            <button className="btn-primary onboarding-btn" disabled={saving} onClick={() => finish(true)}>
              {saving ? "..." : "解説を読む →"}
            </button>
            <button className="onboarding-skip" onClick={() => finish(false)}>あとで（ホームへ）</button>
          </div>
        )}
      </div>
    </div>
  );
}
