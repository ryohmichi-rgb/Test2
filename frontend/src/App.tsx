import { lazy, Suspense } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router";
import AuthPage from "./pages/AuthPage";
import GradesPage from "./pages/GradesPage";
import ProgressPage from "./pages/ProgressPage";
import StatsPage from "./pages/StatsPage";
import PlanPage from "./pages/PlanPage";
import HomePage from "./pages/HomePage";
import OnboardingPage from "./pages/OnboardingPage";
import TestHistoryPage from "./pages/TestHistoryPage";
import SettingsPage from "./pages/SettingsPage";
import ParentHomePage from "./pages/ParentHomePage";
import ParentChildPage from "./pages/ParentChildPage";
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
// 昇格試験も問題文で KaTeX を使うので遅延読み込みにする
const PromotionExamPage = lazy(() => import("./pages/PromotionExamPage"));
const AdminPage = lazy(() => import("./pages/admin/AdminPage"));
const AdminUnitsPage = lazy(() => import("./pages/admin/AdminUnitsPage"));
const AdminProblemsPage = lazy(() => import("./pages/admin/AdminProblemsPage"));
const AdminReferenceStatsPage = lazy(() => import("./pages/admin/AdminReferenceStatsPage"));
const AdminStudentsPage = lazy(() => import("./pages/admin/AdminStudentsPage"));

// 保護者は「見る専用」なので、問題を解く画面や設定画面には入れない。
// バックエンドでも塞いでいるが、入れてしまうと「押せるのに何も起きない」画面になるため
// 手前で保護者のホームへ戻す。
function StudentOnly({ children }: { children: React.ReactNode }) {
  if (localStorage.getItem("role") === "parent") return <Navigate to="/parent" replace />;
  return <>{children}</>;
}

function App() {
  return (
    <PasswordGate>
    <BrowserRouter>
      <Suspense fallback={<div className="loading">読み込み中...</div>}>
      <Routes>
        <Route path="/" element={<AuthPage />} />
        <Route path="/home" element={<StudentOnly><HomePage /></StudentOnly>} />
        <Route path="/onboarding" element={<StudentOnly><OnboardingPage /></StudentOnly>} />
        <Route path="/grades" element={<StudentOnly><GradesPage /></StudentOnly>} />
        <Route path="/units/:unitId" element={<StudentOnly><LessonPage /></StudentOnly>} />
        <Route path="/units/:unitId/practice" element={<StudentOnly><PracticePage /></StudentOnly>} />
        <Route path="/progress/:studentId" element={<StudentOnly><ProgressPage /></StudentOnly>} />
        <Route path="/stats" element={<StudentOnly><StatsPage /></StudentOnly>} />
        <Route path="/plan" element={<StudentOnly><PlanPage /></StudentOnly>} />
        <Route path="/problem-set" element={<StudentOnly><ProblemSetPage /></StudentOnly>} />
        <Route path="/test" element={<StudentOnly><TestPage /></StudentOnly>} />
        <Route path="/test-history" element={<StudentOnly><TestHistoryPage /></StudentOnly>} />
        <Route path="/settings" element={<StudentOnly><SettingsPage /></StudentOnly>} />
        {/* 保護者（見る専用）。子どもの学習状況を読むだけの画面 */}
        <Route path="/parent" element={<ParentHomePage />} />
        <Route path="/parent/children/:childId" element={<ParentChildPage />} />
        <Route path="/review" element={<StudentOnly><ReviewPage /></StudentOnly>} />
        <Route path="/promotion-exam" element={<StudentOnly><PromotionExamPage /></StudentOnly>} />
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
