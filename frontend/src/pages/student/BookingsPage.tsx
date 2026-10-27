import { useState } from 'react';
import { Link } from 'react-router-dom';
import { bookingApi, memberApi } from '../../api/member';
import type { BookingResult, BookingStatus } from '../../api/types';
import { RescheduleDialog } from '../../components/RescheduleDialog';
import { AsyncView, Card, PageHeader, StatTile, StatusPill } from '../../components/ui';
import { useApi } from '../../hooks/useApi';
import { fmtMonthDay, fmtTimeRange, toDateTime, todayISO } from '../../utils/format';
import { countBy } from '../../utils/stats';

type Filter = 'all' | BookingStatus;
const FILTERS: [Filter, string][] = [
  ['all', '全部'],
  ['booked', '已預約'],
  ['completed', '已完成'],
  ['cancelled', '已取消'],
];

export default function BookingsPage() {
  const bookings = useApi((s) => memberApi.bookings(s), []);
  const [filter, setFilter] = useState<Filter>('all');
  const [editing, setEditing] = useState<BookingResult>();
  const [busyId, setBusyId] = useState<number>();
  const [notice, setNotice] = useState<{ tone: 'ok' | 'bad'; text: string }>();

  // 後端規定：今天及以前的預約不能取消或修改
  const changeable = (b: BookingResult) => b.bookingstatus === 'booked' && b.classdate > todayISO();

  const cancel = async (b: BookingResult) => {
    if (!window.confirm(`確定要取消 ${fmtMonthDay(b.classdate)} ${fmtTimeRange(b.starttime, b.endtime)} 的「${b.coursename}」嗎？`)) return;
    setBusyId(b.bookingid);
    setNotice(undefined);
    try {
      const msg = await bookingApi.cancel(b.bookingid);
      setNotice({ tone: 'ok', text: typeof msg === 'string' && msg ? msg : '取消預約成功' });
      bookings.reload();
    } catch (err) {
      setNotice({ tone: 'bad', text: (err as Error).message });
    } finally {
      setBusyId(undefined);
    }
  };

  return (
    <div className="page">
      <PageHeader
        title="預約管理"
        action={
          <Link to="/student/bookings/new" className="btn btn-primary">
            ＋ 新增預約
          </Link>
        }
      />

      <AsyncView state={bookings} minHeight={110}>
        {(list) => {
          const counts = countBy(list, (b) => b.bookingstatus);
          return (
            <div className="tiles">
              <StatTile label="已預約" value={counts.booked ?? 0} unit="堂" hint="待上課" />
              <StatTile label="已完成" value={counts.completed ?? 0} unit="堂" hint="已上課" />
              <StatTile label="已取消" value={counts.cancelled ?? 0} unit="堂" hint="含會員與教練取消" />
            </div>
          );
        }}
      </AsyncView>

      <Card
        title="預約紀錄"
        subtitle="GET /booking/my；明天以後的預約可以修改或取消"
        action={
          <div className="chips" role="group" aria-label="依狀態篩選">
            {FILTERS.map(([value, label]) => (
              <button
                key={value}
                type="button"
                className="chip"
                aria-pressed={filter === value}
                onClick={() => setFilter(value)}
              >
                {label}
              </button>
            ))}
          </div>
        }
      >
        {notice && (
          <p className={`notice notice-${notice.tone}`} role="status">
            {notice.text}
          </p>
        )}
        <AsyncView state={bookings} minHeight={240}>
          {(list) => {
            const rows = list
              .filter((b) => filter === 'all' || b.bookingstatus === filter)
              .sort(
                (a, b) =>
                  toDateTime(b.classdate, b.starttime).getTime() - toDateTime(a.classdate, a.starttime).getTime(),
              );
            if (!rows.length) return <p className="muted">沒有符合的預約</p>;
            return (
              <div className="table-wrap tall">
                <table className="table">
                  <thead>
                    <tr>
                      <th>編號</th>
                      <th>日期</th>
                      <th>時間</th>
                      <th>課程</th>
                      <th>教練</th>
                      <th>教室</th>
                      <th>狀態</th>
                      <th>操作</th>
                    </tr>
                  </thead>
                  <tbody>
                    {rows.map((b) => (
                      <tr key={b.bookingid}>
                        <td>{b.bookingid}</td>
                        <td>{fmtMonthDay(b.classdate)}</td>
                        <td>{fmtTimeRange(b.starttime, b.endtime)}</td>
                        <td>{b.coursename}</td>
                        <td>{b.coachname}</td>
                        <td>{b.classroom}</td>
                        <td>
                          <StatusPill status={b.bookingstatus} />
                        </td>
                        <td>
                          {changeable(b) ? (
                            <div className="row-actions">
                              <button type="button" className="btn btn-small" disabled={busyId !== undefined} onClick={() => setEditing(b)}>
                                改期
                              </button>
                              <button
                                type="button"
                                className="btn btn-small btn-danger"
                                disabled={busyId !== undefined}
                                onClick={() => void cancel(b)}
                              >
                                {busyId === b.bookingid ? '取消中…' : '取消'}
                              </button>
                            </div>
                          ) : (
                            <span className="muted small">—</span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            );
          }}
        </AsyncView>
      </Card>

      {editing && (
        <RescheduleDialog
          booking={editing}
          onClose={() => setEditing(undefined)}
          onDone={(msg) => {
            setEditing(undefined);
            setNotice({ tone: 'ok', text: msg });
            bookings.reload();
          }}
        />
      )}
    </div>
  );
}
