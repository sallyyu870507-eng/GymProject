import { useEffect, useState } from 'react';
import { Outlet, useLocation, useNavigate } from 'react-router-dom';
import Sidebar from './Sidebar';
import './AppShell.css';

/**
 * 版面：左側用組員的 Sidebar（feature/frontend-fangyu 的 src/components/Sidebar.jsx，原檔不修改），
 * 右側放頁面內容。
 *
 * 手機與窄螢幕（768px 以下）：Sidebar 收進漢堡選單，點按鈕從左邊滑出，
 * 點遮罩、按 Esc、或選了選單項目後自動收起。這些只靠外層包裝與 AppShell.css 完成。
 *
 * 依網址決定角色：/student → member、/trainer → coach。
 */
export function AppShell() {
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);

  const base = pathname.startsWith('/trainer') ? '/trainer' : '/student';
  const role = base === '/trainer' ? 'coach' : 'member';
  const rest = pathname.slice(base.length).replace(/^\//, '').split('/')[0];
  const activeItem = rest || 'home';

  // 換頁就收起選單
  useEffect(() => setOpen(false), [pathname]);

  // Esc 收起選單
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && setOpen(false);
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open]);

  return (
    <div className={`app-layout ${open ? 'nav-open' : ''}`}>
      <header className="mobile-bar">
        <button
          type="button"
          className="hamburger"
          aria-label="開啟選單"
          aria-expanded={open}
          aria-controls="app-nav"
          onClick={() => setOpen(true)}
        >
          <span />
          <span />
          <span />
        </button>
        <span className="mobile-title">力量健身</span>
        <span className="mobile-role">{role === 'coach' ? '教練' : '學員'}</span>
      </header>

      <div className="nav-drawer" id="app-nav">
        <button type="button" className="drawer-close" aria-label="收起選單" onClick={() => setOpen(false)}>
          ×
        </button>
        {/* Sidebar 只在第一次出現時讀 role，換角色時用 key 讓它重新建立 */}
        <Sidebar
          key={role}
          role={role}
          activeItem={activeItem}
          onNavigate={(key) => {
            setOpen(false);
            navigate(key === 'home' ? base : `${base}/${key}`);
          }}
        />
      </div>
      <div className="nav-scrim" aria-hidden onClick={() => setOpen(false)} />

      <main className="main">
        <Outlet />
      </main>
    </div>
  );
}
