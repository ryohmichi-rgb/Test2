import { useEffect } from "react";
import { useNavigate } from "react-router-dom";

// 管理者以外はホームへ戻す
export function useAdminGuard() {
  const navigate = useNavigate();
  useEffect(() => {
    if (localStorage.getItem("admin") !== "1") navigate("/home");
  }, [navigate]);
}
