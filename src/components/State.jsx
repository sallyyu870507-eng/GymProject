import { Link } from "react-router-dom";
import { useAuth } from "../auth/AuthContext.jsx";

export const Loading = () => <div className="state">載入中…</div>;

export function ErrorState({ error }) {
  const { logout } = useAuth();
  const authish = [401, 403, 500].includes(error?.status);
  return (
    <div className="state error" role="alert">
      {error?.message ?? "發生錯誤"}
      {authish && (
        <p className="hint">若是登入逾時或權限不足，請<Link to="/login" onClick={logout}>重新登入</Link>。</p>
      )}
    </div>
  );
}
