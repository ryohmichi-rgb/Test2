import { lazy, Suspense } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import AuthPage from "./pages/AuthPage";
import GradesPage from "./pages/GradesPage";
import ProgressPage from "./pages/ProgressPage";
import StatsPage from "./pages/StatsPage";
import PlanPage from "./pages/PlanPage";
import HomePage from "./pages/HomePage";
import OnboardingPage from "./pages/OnboardingPage";
import TestHistoryPage from "./pages/TestHistoryPage";
import SettingsPage from "./pages/SettingsPage";
import PasswordGate from "./components/PasswordGate";
import "./App.css";

// 遅延読み込み（初回に読むJSを軽くする）
// - 教材ページ: react-markdown と KaTeX が重いので、開いたときだけ読み込む
// - 問題を解く4画面: 問題文の数式で KaTeX を使う。ログイン直後には要らない
// - 管理ページ: 管理者しか使わないので、生徒には読み込ませない
// KaTeX はこれらの共有チャンクに入り、主バンドルからは外れる。
const LessonPage = lazy(() => import("./pages/LessonPage"));
const PracticePage = lazy(() => import("./pages/PracticePage"));
const ProblemSetPage = lazy(() => import("./pages/ProblemSetPage"));
const TestPage = lazy(() => import("./pages/TestPage"));
const ReviewPage = lazy(() => import("./pages/ReviewPage"));
const AdminPage = lazy(() => import("./pages/admin/AdminPage"));
const AdminUnitsPage = lazy(() => import("./pages/admin/AdminUnitsPage"));
const AdminProblemsPage = lazy(() => import("./pages/admin/AdminProblemsPage"));
const AdminReferenceStatsPage = lazy(() => import("./pages/admin/AdminReferenceStatsPage"));
const AdminStudentsPage = lazy(() => import("./pages/admin/AdminStudentsPage"));

function App() {
  return (
    <PasswordGate>
    <BrowserRouter>
      <Suspense fallback={<div className="loading">読み込み中...</div>}>
      <Routes>
        <Route path="/" element={<AuthPage />} />
        <Route path="/home" element={<HomePage />} />
        <Route path="/onboarding" element={<OnboardingPage />} />
        <Route path="/grades" element={<GradesPage />} />
        <Route path="/units/:unitId" element={<LessonPage />} />
        <Route path="/units/:unitId/practice" element={<PracticePage />} />
        <Route path="/progress/:studentId" element={<ProgressPage />} />
        <Route path="/stats" element={<StatsPage />} />
        <Route path="/plan" element={<PlanPage />} />
        <Route path="/problem-set" element={<ProblemSetPage />} />
        <Route path="/test" element={<TestPage />} />
        <Route path="/test-history" element={<TestHistoryPage />} />
        <Route path="/settings" element={<SettingsPage />} />
        <Route path="/review" element={<ReviewPage />} />
        <Route path="/admin" element={<AdminPage />} />
        <Route path="/admin/units" element={<AdminUnitsPage />} />
        <Route path="/admin/units/:unitId/problems" element={<AdminProblemsPage />} />
        <Route path="/admin/reference" element={<AdminReferenceStatsPage />} />
        <Route path="/admin/students" element={<AdminStudentsPage />} />
        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
      </Suspense>
    </BrowserRouter>
    </PasswordGate>
  );
}

export default App;
