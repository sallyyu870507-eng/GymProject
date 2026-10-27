import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import { authApi } from '../api/auth';
import { USE_MOCK } from '../api/mock';
import { setUnauthorizedHandler } from '../api/client';
import type { Role, SessionUser } from '../api/types';

/** 各角色登入後的首頁 */
export const HOME: Record<Role, string> = { member: '/student', coach: '/trainer', admin: '/manage' };
export const ROLE_LABEL: Record<Role, string> = { member: '學員', coach: '教練', admin: '管理員' };

interface AuthValue {
  user: SessionUser | null;
  login: (username: string, password: string) => Promise<SessionUser>;
  testLogin: (role: Role) => Promise<SessionUser>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthValue | null>(null);
const STORAGE_KEY = 'powergym.user';

function loadUser(): SessionUser | null {
  try {
    const raw = sessionStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as SessionUser) : null;
  } catch {
    return null;
  }
}

function storeUser(user: SessionUser | null) {
  try {
    if (user) sessionStorage.setItem(STORAGE_KEY, JSON.stringify(user));
    else sessionStorage.removeItem(STORAGE_KEY);
  } catch {
    /* 無痕模式等情況可能無法存，忽略 */
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<SessionUser | null>(loadUser);
  const navigate = useNavigate();

  const save = (next: SessionUser | null) => {
    storeUser(next);
    setUser(next);
  };

  // 任何 API 回 401：Session 過期或後端重啟，清掉狀態回登入頁
  useEffect(() => {
    setUnauthorizedHandler(() => {
      storeUser(null);
      setUser(null);
      navigate('/signin', { replace: true });
    });
    return () => setUnauthorizedHandler(undefined);
  }, [navigate]);

  // 重新整理頁面時跟後端確認 Session 還在（GET /api/user），順便更新姓名；過期會觸發上面的 401 處理
  useEffect(() => {
    if (USE_MOCK || !user) return;
    authApi
      .me()
      .then((u) => save(u))
      .catch(() => {
        /* 401 已由 unauthorizedHandler 處理 */
      });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const value = useMemo<AuthValue>(
    () => ({
      user,
      login: async (username, password) => {
        const u = await authApi.login(username, password);
        save(u);
        return u;
      },
      testLogin: async (role) => {
        const u = await authApi.testLogin(role);
        save(u);
        return u;
      },
      logout: async () => {
        await authApi.logout();
        save(null);
      },
    }),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [user],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth 必須在 <AuthProvider> 裡使用');
  return ctx;
}

/** 路由守衛：沒登入回登入頁；角色不符導回自己的首頁 */
export function RequireRole({ role, children }: { role: Role; children: ReactNode }) {
  const { user } = useAuth();
  if (!user) return <Navigate to="/signin" replace />;
  if (user.role !== role) return <Navigate to={HOME[user.role]} replace />;
  return <>{children}</>;
}
