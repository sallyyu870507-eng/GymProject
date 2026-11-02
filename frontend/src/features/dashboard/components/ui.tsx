import type { ReactNode } from 'react';
import { Link } from 'react-router';

/* ───────────── 卡片 ───────────── */

interface CardProps {
  title?: ReactNode;
  subtitle?: ReactNode;
  action?: ReactNode;
  footer?: ReactNode;
  className?: string;
  id?: string;
  children?: ReactNode;
}

export function Card({ title, subtitle, action, footer, className, id, children }: CardProps) {
  return (
    <section className={`card ${className ?? ''}`} id={id}>
      {(title || action) && (
        <header className="card-head">
          <div>
            {title && <h3>{title}</h3>}
            {subtitle && <p className="muted small">{subtitle}</p>}
          </div>
          {action}
        </header>
      )}
      {children}
      {footer && <footer className="card-foot">{footer}</footer>}
    </section>
  );
}

/* ───────────── 數字方塊 ───────────── */

interface StatTileProps {
  label: string;
  value: ReactNode;
  unit?: string;
  hint?: ReactNode;
  tone?: 'good' | 'bad' | 'warn';
}

export function StatTile({ label, value, unit, hint, tone }: StatTileProps) {
  return (
    <div className="card tile">
      <span className="tile-label">{label}</span>
      <span className={`tile-value ${tone ? `tone-${tone}` : ''}`}>
        {value}
        {unit && <small>{unit}</small>}
      </span>
      {hint && <span className="tile-hint">{hint}</span>}
    </div>
  );
}

/* ───────────── 頁首 ───────────── */

interface PageHeaderProps {
  title: string;
  /** 返回連結；傳 false 不顯示 */
  back?: { to: string; label: string } | false;
  action?: ReactNode;
}

export function PageHeader({ title, back = { to: '/student', label: '返回總覽' }, action }: PageHeaderProps) {
  return (
    <div className="page-head">
      <div>
        {back && (
          <Link to={back.to} className="back-link">
            ← {back.label}
          </Link>
        )}
        <h1>{title}</h1>
      </div>
      {action}
    </div>
  );
}

/* ───────────── 狀態標籤 ───────────── */

const STATUS_TEXT: Record<string, string> = {
  booked: '已預約',
  completed: '已完成',
  cancelled: '已取消',
  available: '可預約',
  closed: '不開放',
  private: '私人安排',
  active: '啟用',
  inactive: '停用',
  open: '可預約',
  // attendance.attendancestatus
  present: '出席',
  absent: '缺席',
  leave: '請假',
  pending: '待簽到',
};

/** 大小寫都接受：BOOKED、booked 都顯示「已預約」 */
export function StatusPill({ status }: { status: string }) {
  const key = (status ?? '').trim().toLowerCase();
  return <span className={`pill pill-${key}`}>{STATUS_TEXT[key] ?? status}</span>;
}

/* ───────────── 進度條 ───────────── */

export function ProgressBar({ ratio, tone }: { ratio: number; tone?: 'bad' }) {
  const pct = Math.max(0, Math.min(1, ratio)) * 100;
  return (
    <div className="bar" role="progressbar" aria-valuenow={Math.round(pct)} aria-valuemin={0} aria-valuemax={100}>
      <span className={tone === 'bad' ? 'bar-bad' : undefined} style={{ width: `${pct}%` }} />
    </div>
  );
}
