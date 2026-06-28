import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import StartPage from "./pages/StartPage";
import GradesPage from "./pages/GradesPage";
import PracticePage from "./pages/PracticePage";
import ProgressPage from "./pages/ProgressPage";
import PasswordGate from "./components/PasswordGate";
import "./App.css";

function App() {
  return (
    <PasswordGate>
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<StartPage />} />
        <Route path="/grades" element={<GradesPage />} />
        <Route path="/units/:unitId" element={<PracticePage />} />
        <Route path="/progress/:studentId" element={<ProgressPage />} />
        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </BrowserRouter>
    </PasswordGate>
  );
}

export default App;
