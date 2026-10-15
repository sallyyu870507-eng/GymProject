import { useEffect, useState } from "react";
import { NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";
import Brand from "./Brand.jsx";
import { useAuth } from "../auth/AuthContext.jsx";
import { toggleTheme } from "../theme.js";

// 側邊欄版面：電腦版固定在左側；手機版（≤768px）收成抽屜，用 ☰ 開關
export default function Layout({ roleLabel, links }) {
  const { auth, logout } = useAuth();
  const [open, setOpen] = useState(false);
  const { pathname } = useLocation();
  const nav = useNavigate();

  useEffect(() => setOpen(false), [pathname]);
  useEffect(() => {
    const onKey = e => e.key === "Escape" && setOpen(false);
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  const onLogout = () => { logout(); nav("/"); };

  return (
    <div className={`layout ${open ? "nav-open" : ""}`}>
      <div className="topbar">
        <button className="icon-btn" aria-label="開啟選單" aria-expanded={open} aria-controls="sidebar"
                onClick={() => setOpen(o => !o)}>☰</button>
        <Brand />
      </div>
      <div className="backdrop" onClick={() => setOpen(false)} />

      <aside className="sidebar" id="sidebar">
        <Brand />
        <span className="role-tag">{roleLabel}</span>
        <nav className="side-nav">
          {links.map(l => (
            <NavLink key={l.to} to={l.to} className={({ isActive }) => (isActive ? "active" : "")}>
              <span aria-hidden="true">{l.icon}</span>{l.label}
            </NavLink>
          ))}
        </nav>
        <div className="side-foot">
          {auth?.name && <span className="user">👤 {auth.name}</span>}
          <div className="row">
            <button className="btn ghost sm" onClick={onLogout}>登出</button>
            <button className="btn ghost sm" onClick={toggleTheme} aria-label="切換深淺色">◐ 深/淺色</button>
          </div>
        </div>
      </aside>

      <main className="content"><Outlet /></main>
    </div>
  );
}
