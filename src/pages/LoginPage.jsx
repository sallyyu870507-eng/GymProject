import { useState } from "react";
import { Navigate, useNavigate } from "react-router-dom";
import Brand from "../components/Brand.jsx";
import { useAuth } from "../auth/AuthContext.jsx";
import { toggleTheme } from "../theme.js";

export default function LoginPage() {
  const { auth, login } = useAuth();
  const nav = useNavigate();
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  // 已登入就直接進自己的畫面
  if (auth?.role) return <Navigate to={`/${auth.role}`} replace />;

  const submit = async e => {
    e.preventDefault();
    const d = new FormData(e.target);
    setBusy(true); setError("");
    try {
      const role = await login(String(d.get("account")).trim(), String(d.get("password")));
      nav(`/${role}`, { replace: true });     // 會員 → /member、教練 → /coach、管理員 → /admin
    } catch (err) {
      setError([400, 401, 403].includes(err.status) ? "帳號或密碼錯誤" : err.message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="public">
      <div className="topbar always"><Brand /><span className="spacer" />
        <button className="btn ghost sm" onClick={toggleTheme} aria-label="切換深淺色">◐</button>
      </div>
      <main className="content narrow">
        <div className="card login">
          <img src="/logo-full.png" alt="POWER GYM 力量健身" />
          <h2>登入</h2>
          <form onSubmit={submit}>
            <label>帳號<input name="account" required autoFocus autoComplete="username" /></label>
            <label>密碼<input name="password" type="password" required autoComplete="current-password" /></label>
            <button className="btn" type="submit" disabled={busy}>{busy ? "登入中…" : "登入"}</button>
            {error && <div className="state error" role="alert">{error}</div>}
          </form>
        </div>
      </main>
    </div>
  );
}
