import { Link, NavLink, Outlet, useNavigate } from 'react-router-dom';
import { USE_MOCK } from '../api/mock';
import type { Role } from '../api/types';
import { HOME, ROLE_LABEL, useAuth } from '../auth/AuthContext';

const NAV: Record<Role, { to: string; label: string; end?: boolean }[]> = {
  member: [
    { to: '/student', label: '總覽', end: true },
    { to: '/student/remind', label: '課堂提醒' },
    { to: '/student/profile', label: '會員管理' },
    { to: '/student/inbody', label: 'InBody 分析' },
    { to: '/student/courses', label: '課程管理' },
    { to: '/student/bookings', label: '預約管理' },
  ],
  coach: [
    { to: '/trainer', label: '今日教學課表', end: true },
    { to: '/trainer/members', label: '我的學員' },
  ],
  admin: [{ to: '/manage', label: '會員管理', end: true }],
};

export function AppShell() {
  const { user, logout, testLogin } = useAuth();
  const navigate = useNavigate();
  if (!user) return null;

  const switchRole = async (role: Role) => {
    await testLogin(role);
    navigate(HOME[role]);
  };

  return (
    <div className="shell">
      <header className="topbar">
        <div className="topbar-inner">
          <Link to={HOME[user.role]} className="brand">
            POWER GYM
          </Link>
          <span className="role-tag">{ROLE_LABEL[user.role]}端</span>
          {USE_MOCK && <span className="mock-tag">示範資料</span>}
          <div className="spacer" />
          {USE_MOCK && (
            <select
              className="select"
              aria-label="切換角色（示範用）"
              value={user.role}
              onChange={(e) => void switchRole(e.target.value as Role)}
            >
              <option value="member">看學員端</option>
              <option value="coach">看教練端</option>
              <option value="admin">看管理員端</option>
            </select>
          )}
          <button
            type="button"
            className="btn btn-ghost"
            onClick={async () => {
              await logout();
              navigate('/signin');
            }}
          >
            登出
          </button>
        </div>
        <nav className="tabs" aria-label="功能選單">
          {NAV[user.role].map((item) => (
            <NavLink key={item.to} to={item.to} end={item.end} className="tab">
              {item.label}
            </NavLink>
          ))}
        </nav>
      </header>
      <main className="main">
        <Outlet />
      </main>
    </div>
  );
}
