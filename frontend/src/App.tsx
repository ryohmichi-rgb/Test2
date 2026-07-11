import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import StartPage from "./pages/StartPage";
import GradesPage from "./pages/GradesPage";
import PracticePage from "./pages/PracticePage";
import ProgressPage from "./pages/ProgressPage";
import StatsPage from "./pages/StatsPage";
import PlanPage from "./pages/PlanPage";
import HomePage from "./pages/HomePage";
import ProblemSetPage from "./pages/ProblemSetPage";
import TestPage from "./pages/TestPage";
import TestHistoryPage from "./pages/TestHistoryPage";
import PasswordGate from "./components/PasswordGate";
import "./App.css";

function App() {
  return (
    <PasswordGate>
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<StartPage />} />
        <Route path="/home" element={<HomePage />} />
        <Route path="/grades" element={<GradesPage />} />
        <Route path="/units/:unitId" element={<PracticePage />} />
        <Route path="/progress/:studentId" element={<ProgressPage />} />
        <Route path="/stats" element={<StatsPage />} />
        <Route path="/plan" element={<PlanPage />} />
        <Route path="/problem-set" element={<ProblemSetPage />} />
        <Route path="/test" element={<TestPage />} />
        <Route path="/test-history" element={<TestHistoryPage />} />
        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </BrowserRouter>
    </PasswordGate>
  );
}

export default App;
