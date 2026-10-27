import { useState, type FormEvent } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import { USE_MOCK } from '../api/mock';
import type { Role } from '../api/types';
import { HOME, useAuth } from '../auth/AuthContext';

export default function SignInPage() {
  const { user, login, testLogin } = useAuth();
  const navigate = useNavigate();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string>();
  const [busy, setBusy] = useState(false);

  if (user) return <Navigate to={HOME[user.role]} replace />;

  const run = async (action: () => Promise<{ role: Role }>) => {
    setBusy(true);
    setError(undefined);
    try {
      const u = await action();
      navigate(HOME[u.role], { replace: true });
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setBusy(false);
    }
  };

  const onSubmit = (e: FormEvent) => {
    e.preventDefault();
    void run(() => login(username.trim(), password));
  };

  return (
    <div className="signin">
      <form className="card signin-card" onSubmit={onSubmit}>
        <div className="brand brand-lg">POWER GYM</div>
        <p className="muted">登入會員、教練或管理員帳號</p>

        <label className="field">
          <span>帳號</span>
          <input value={username} onChange={(e) => setUsername(e.target.value)} autoComplete="username" required />
        </label>
        <label className="field">
          <span>密碼</span>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="current-password"
            required
          />
        </label>

        {error && <p className="form-error">{error}</p>}

        <button type="submit" className="btn btn-primary btn-block" disabled={busy}>
          {busy ? '登入中…' : '登入'}
        </button>

        {USE_MOCK ? (
          <>
            <div className="divider">示範模式：直接進入</div>
            <div className="quick-login">
              {(['member', 'coach', 'admin'] as Role[]).map((role) => (
                <button key={role} type="button" className="btn" disabled={busy} onClick={() => void run(() => testLogin(role))}>
                  {{ member: '學員', coach: '教練', admin: '管理員' }[role]}
                </button>
              ))}
            </div>
            <p className="muted small">示範模式下帳號開頭是 coach / admin 會以該角色登入，其餘為學員。</p>
          </>
        ) : (
          <>
            <div className="divider">開發用測試帳號（組員測試資料）</div>
            <div className="quick-login">
              {(
                [
                  ['學員', 'member001', '123456'],
                  ['教練', 'AMY', '123456'],
                  ['管理員', 'admin01', 'admin1234'],
                ] as const
              ).map(([label, u, p]) => (
                <button key={u} type="button" className="btn" disabled={busy} onClick={() => void run(() => login(u, p))}>
                  {label}
                </button>
              ))}
            </div>
          </>
        )}
      </form>
    </div>
  );
}
