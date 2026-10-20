import type { ReactNode } from 'react';
import type { MemberListItem, MemberListPage } from '../api/types';
import { StatusPill } from './ui';

interface Props {
  data: MemberListPage;
  /** 每一列最右邊的按鈕 */
  actions: (m: MemberListItem) => ReactNode;
  onPage: (page: number) => void;
  /** 教練端不顯示帳號狀態 */
  showStatus?: boolean;
}

/** 會員清單表格（管理員與教練共用），欄位對應 MemberListDTO */
export function MemberTable({ data, actions, onPage, showStatus = true }: Props) {
  return (
    <>
      <div className="table-wrap tall">
        <table className="table">
          <thead>
            <tr>
              <th>會員編號</th>
              <th>姓名</th>
              <th>性別</th>
              <th>手機</th>
              <th>購買課程（剩餘堂數）</th>
              {showStatus && <th>狀態</th>}
              <th className="num">操作</th>
            </tr>
          </thead>
          <tbody>
            {data.members.map((m) => (
              <tr key={m.memberid} className={m.status === 'inactive' ? 'row-past' : undefined}>
                <td>{m.memberno}</td>
                <td>{m.name}</td>
                <td>{m.gender || '—'}</td>
                <td>{m.phone}</td>
                <td className="wrap">
                  {m.courses.length ? (
                    <div className="course-tags">
                      {m.courses.map((c, i) => (
                        <span key={`${c.coursename}-${i}`} className={`course-tag ${c.remainingsessions <= 2 ? 'low' : ''}`}>
                          {c.coursename} <b>{c.remainingsessions}</b>
                        </span>
                      ))}
                    </div>
                  ) : (
                    <span className="muted">—</span>
                  )}
                </td>
                {showStatus && (
                  <td>
                    <StatusPill status={String(m.status)} />
                  </td>
                )}
                <td className="num">
                  <div className="row-actions">{actions(m)}</div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {!data.members.length && <p className="muted empty">沒有符合條件的會員</p>}
      </div>

      <div className="pager">
        <span className="muted small">共 {data.totalElements} 位</span>
        <button type="button" className="btn btn-small" disabled={!data.hasPrev} onClick={() => onPage(data.currentPage - 1)}>
          上一頁
        </button>
        <span className="muted small">
          第 {data.currentPage + 1} / {Math.max(1, data.totalPages)} 頁
        </span>
        <button type="button" className="btn btn-small" disabled={!data.hasNext} onClick={() => onPage(data.currentPage + 1)}>
          下一頁
        </button>
      </div>
    </>
  );
}
