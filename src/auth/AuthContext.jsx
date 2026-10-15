import { createContext, useContext, useState } from "react";
import { gymApi } from "../api/gymApi.js";

// 真正的登入狀態在後端 Session（Cookie）；這裡只記「目前是哪個身分」供畫面使用
const KEY = "gym-auth";
const ROLES = ["member", "coach", "admin"];
const read = () => { try { return JSON.parse(sessionStorage.getItem(KEY)); } catch { return null; } };
const Ctx = createContext(null);

export function AuthProvider({ children }) {
  const [auth, setAuth] = useState(read);

  // 帳號密碼登入；依後端回傳的 role 決定進哪個身分的畫面，回傳 role
  const login = async (account, password) => {
    const r = await gymApi.login(account, password);
    const role = String(r?.role ?? "").toLowerCase();
    if (!ROLES.includes(role))
      throw new Error("登入成功，但後端沒有回傳可辨識的身分（role 必須是 member、coach 或 admin）");
    const a = { role, name: r?.name };
    try { sessionStorage.setItem(KEY, JSON.stringify(a)); } catch {}
    setAuth(a);
    return role;
  };

  const logout = () => {
    try { sessionStorage.removeItem(KEY); } catch {}
    setAuth(null);   // 後端目前沒有登出 API，Session 會在後端逾時後失效
  };

  return <Ctx.Provider value={{ auth, login, logout }}>{children}</Ctx.Provider>;
}

export const useAuth = () => useContext(Ctx);
