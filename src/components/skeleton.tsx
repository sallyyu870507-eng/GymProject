import type { ReactNode } from 'react';

/**
 * 版面骨架用的空白元件：之後接上資料時，把這些換成真正的內容即可。
 */

/** 圖表、圖片等區塊的預留位置 */
export function Placeholder({ label, height = 200 }: { label: string; height?: number }) {
  return (
    <div className="placeholder" style={{ minHeight: height }}>
      <span>{label}</span>
    </div>
  );
}

/** 只有欄位標題的表格，內容顯示「尚無資料」；fill=true 時延伸到卡片底部 */
export function EmptyTable({ columns, numeric = [], emptyText = '尚無資料', fill = false }: {
  columns: string[];
  /** 靠右對齊的欄位（數字） */
  numeric?: string[];
  emptyText?: string;
  /** 放在 .card-fill 裡時，空白區延伸填滿剩下的高度 */
  fill?: boolean;
}) {
  const head = (
    <thead>
      <tr>
        {columns.map((c) => (
          <th key={c} className={numeric.includes(c) ? 'num' : undefined}>
            {c}
          </th>
        ))}
      </tr>
    </thead>
  );

  if (fill) {
    return (
      <div className="table-wrap table-fill">
        <table className="table">{head}</table>
        <div className="empty-fill muted">{emptyText}</div>
      </div>
    );
  }

  return (
    <div className="table-wrap">
      <table className="table">
        {head}
        <tbody>
          <tr>
            <td colSpan={columns.length} className="empty muted">
              {emptyText}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  );
}

/** 「欄位名稱：值」清單，值先顯示「—」 */
export function MetaList({ fields, large }: { fields: string[]; large?: boolean }) {
  return (
    <dl className={`meta ${large ? 'meta-lg' : ''}`}>
      {fields.map((f) => (
        <Field key={f} label={f} />
      ))}
    </dl>
  );
}

function Field({ label, value = '—' }: { label: string; value?: ReactNode }) {
  return (
    <>
      <dt>{label}</dt>
      <dd>{value}</dd>
    </>
  );
}

/** 數字小格（首頁卡片裡的三、四個數字） */
export function MiniStats({ labels }: { labels: string[] }) {
  return (
    <div className="mini-stats">
      {labels.map((l) => (
        <div key={l}>
          <b>—</b>
          <span>{l}</span>
        </div>
      ))}
    </div>
  );
}

/** 頭像預留位置 */
export function AvatarPlaceholder() {
  return <div className="avatar avatar-empty" aria-hidden />;
}
