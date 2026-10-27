import { ApiError, buildUrl, http } from './client';
import { ENDPOINTS } from './endpoints';
import { USE_MOCK, sleep } from './mock';
import type { CurrentUser, Role, SessionUser } from './types';

/** LoginController 失敗時會 redirect 到 /login?error=xxx */
const LOGIN_ERRORS: Record<string, string> = {
  invalid: '帳號或密碼錯誤',
  inactive: '此帳號已停用',
  usernameEmpty: '請輸入帳號',
  passwordEmpty: '請輸入密碼',
};

/** LoginController 成功時依角色 redirect 到這三個路徑 */
const ROLE_BY_PATH: Record<string, Role> = { '/admin': 'admin', '/coach': 'coach', '/member': 'member' };

const DEMO_NAMES: Record<Role, string> = { member: '王小明', coach: '王教練', admin: '管理員' };

export const authApi = {
  /**
   * 對應 LoginController 的 @PostMapping("/login")（@RequestParam username / password）。
   * 後端回的是 redirect 而不是 JSON，所以看「最後停在哪個網址」判斷成功或失敗，
   * 成功後再呼叫 GET /api/user 取得姓名與角色。
   */
  async login(username: string, password: string): Promise<SessionUser> {
    if (USE_MOCK) {
      await sleep(300);
      const role: Role = username.startsWith('admin') ? 'admin' : username.startsWith('coach') ? 'coach' : 'member';
      return { role, name: DEMO_NAMES[role] };
    }

    let res: Response;
    try {
      res = await fetch(buildUrl(ENDPOINTS.auth.login), {
        method: 'POST',
        body: new URLSearchParams({ username, password }),
        credentials: 'include',
        redirect: 'follow',
      });
    } catch {
      throw new ApiError(0, '無法連線到後端，請確認 Spring Boot 已啟動');
    }

    const finalUrl = new URL(res.url || window.location.href, window.location.origin);
    const error = finalUrl.searchParams.get('error');
    if (error) throw new ApiError(401, LOGIN_ERRORS[error] ?? '登入失敗');

    const role = ROLE_BY_PATH[finalUrl.pathname.replace(/\.html$/, '')];
    if (!role) throw new ApiError(res.status, `無法判斷登入結果（停在 ${finalUrl.pathname}）`);

    try {
      return await authApi.me();
    } catch {
      return { role, name: username, username };
    }
  },

  /** ApiUserController GET /api/user：目前登入者；Session 過期會回 401 */
  async me(): Promise<SessionUser> {
    if (USE_MOCK) throw new ApiError(0, '示範模式沒有 Session');
    const u = await http.get<CurrentUser>(ENDPOINTS.auth.me);
    return { role: u.role, name: u.name, username: u.username };
  },

  async logout(): Promise<void> {
    if (USE_MOCK) return;
    try {
      await fetch(buildUrl(ENDPOINTS.auth.logout), { method: 'POST', credentials: 'include' });
    } catch {
      /* 登出失敗也照樣清掉前端狀態 */
    }
  },

  /** 規格書第 3 章的測試登入（/session-test/login-xxx），只在開發時使用 */
  async testLogin(role: Role): Promise<SessionUser> {
    if (!USE_MOCK) {
      const res = await fetch(buildUrl(ENDPOINTS.auth.testLogin(role)), { credentials: 'include' });
      if (!res.ok) throw new ApiError(res.status, '測試登入失敗，後端可能沒有 /session-test');
    } else {
      await sleep(200);
    }
    return { role, name: DEMO_NAMES[role] };
  },
};
