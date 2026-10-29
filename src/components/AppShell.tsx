import { Outlet, useLocation, useNavigate } from 'react-router-dom';
import Sidebar from './Sidebar';

/**
 * 版面：左側用組員的 Sidebar（feature/frontend-fangyu 的 src/components/Sidebar.jsx，原檔不修改），
 * 右側放頁面內容。
 *
 * 依網址決定角色：/student → member、/trainer → coach。
 * Sidebar 的選單 key 對應網址：'home' → /student 或 /trainer，其他 key → /student/{key}、/trainer/{key}
 * （那些頁面由組員製作，還沒加入前會導回首頁）。
 */
export function AppShell() {
  const { pathname } = useLocation();
  const navigate = useNavigate();

  const base = pathname.startsWith('/trainer') ? '/trainer' : '/student';
  const role = base === '/trainer' ? 'coach' : 'member';
  const rest = pathname.slice(base.length).replace(/^\//, '').split('/')[0];
  const activeItem = rest || 'home';

  return (
    <div className="app-layout">
      {/* Sidebar 只在第一次出現時讀 role，換角色時用 key 讓它重新建立 */}
      <Sidebar
        key={role}
        role={role}
        activeItem={activeItem}
        onNavigate={(key) => navigate(key === 'home' ? base : `${base}/${key}`)}
      />
      <main className="main">
        <Outlet />
      </main>
    </div>
  );
}
