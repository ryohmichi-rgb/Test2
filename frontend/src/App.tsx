import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import AuthPage from "./pages/AuthPage";
import GradesPage from "./pages/GradesPage";
import PracticePage from "./pages/PracticePage";
import LessonPage from "./pages/LessonPage";
import ProgressPage from "./pages/ProgressPage";
import StatsPage from "./pages/StatsPage";
import PlanPage from "./pages/PlanPage";
import HomePage from "./pages/HomePage";
import OnboardingPage from "./pages/OnboardingPage";
import ProblemSetPage from "./pages/ProblemSetPage";
import TestPage from "./pages/TestPage";
import TestHistoryPage from "./pages/TestHistoryPage";
import ReviewPage from "./pages/ReviewPage";
import AdminPage from "./pages/admin/AdminPage";
import AdminUnitsPage from "./pages/admin/AdminUnitsPage";
import AdminProblemsPage from "./pages/admin/AdminProblemsPage";
import AdminReferenceStatsPage from "./pages/admin/AdminReferenceStatsPage";
import AdminStudentsPage from "./pages/admin/AdminStudentsPage";
import PasswordGate from "./components/PasswordGate";
import "./App.css";

function App() {
  return (
    <PasswordGate>
    <BrowserRouter>
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
        <Route path="/review" element={<ReviewPage />} />
        <Route path="/admin" element={<AdminPage />} />
        <Route path="/admin/units" element={<AdminUnitsPage />} />
        <Route path="/admin/units/:unitId/problems" element={<AdminProblemsPage />} />
        <Route path="/admin/reference" element={<AdminReferenceStatsPage />} />
        <Route path="/admin/students" element={<AdminStudentsPage />} />
        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </BrowserRouter>
    </PasswordGate>
  );
}

export default App;
