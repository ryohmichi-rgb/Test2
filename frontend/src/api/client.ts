import axios from "axios";

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || "http://localhost:3000/api/v1",
  headers: { "Content-Type": "application/json" },
});

// リクエストにログイントークンを付与
api.interceptors.request.use((config) => {
  const token = localStorage.getItem("token");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// 認証切れ（401）ならログイン画面に戻す
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem("token");
      localStorage.removeItem("studentId");
      localStorage.removeItem("studentName");
      if (window.location.pathname !== "/") window.location.href = "/";
    }
    return Promise.reject(err);
  }
);

export default api;
