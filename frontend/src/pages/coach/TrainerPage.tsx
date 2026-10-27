import { useState } from 'react';
import { coachApi } from '../../api/coach';
import { useAuth } from '../../auth/AuthContext';
import { ScheduleGrid, ScheduleLegend } from '../../components/ScheduleGrid';
import { AsyncView, Card, StatTile } from '../../components/ui';
import { useApi, useNow } from '../../hooks/useApi';
import type { CoachScheduleItem } from '../../api/types';
import { fmtMonthDay, fmtPercent, fmtTime, fmtTimeRange, toDateTime, todayISO } from '../../utils/format';

/** 教練首頁：依 Figma 線框稿（今日教學課表 + 全館教練排課表） */
export default function TrainerPage() {
  const { user } = useAuth();
  const now = useNow();
  // 預設今天；測試資料集中在 2026-11-01 ~ 11-13，可以切到那幾天看
  const [date, setDate] = useState(todayISO);
  const isToday = date === todayISO();

  const stats = useApi((s) => coachApi.dashboard(date, s), [date]);
  const today = useApi((s) => coachApi.schedules(date, s), [date]);
  const gym = useApi((s) => coachApi.gymDay(date, s), [date]);

  const sorted = [...(today.data ?? [])].sort((a, b) => a.starttime.localeCompare(b.starttime));
  const next = isToday ? sorted.find((r) => toDateTime(date, r.starttime) > now) : undefined;

  const [busyId, setBusyId] = useState<number>();
  const [notice, setNotice] = useState<{ tone: 'ok' | 'bad'; text: string }>();

  /** PUT /coaches/{bookingid}/coach-cancel */
  const cancel = async (r: CoachScheduleItem) => {
    if (!window.confirm(`確定要幫 ${r.studentname} 取消 ${fmtTimeRange(r.starttime, r.endtime)} 的「${r.coursename}」嗎？`)) return;
    setBusyId(r.bookingid);
    setNotice(undefined);
    try {
      const msg = await coachApi.cancelBooking(r.bookingid);
      setNotice({ tone: 'ok', text: typeof msg === 'string' && msg ? msg : '教練代取消成功' });
      today.reload();
      stats.reload();
      gym.reload();
    } catch (err) {
      setNotice({ tone: 'bad', text: (err as Error).message });
    } finally {
      setBusyId(undefined);
    }
  };

  const gymRows = gym.data ?? [];
  const booked = gymRows.filter((r) => r.status === 'booked').length;
  const open = gymRows.filter((r) => r.status === 'available').length;

  return (
    <div className="page">
      <div className="page-head">
        <h1 className="hello">你好，{user?.name}</h1>
        <label className="date-picker">
          查看日期
          <input
            type="date"
            value={date}
            min="2000-01-01"
            max="2099-12-31"
            onChange={(e) => e.target.value && setDate(e.target.value)}
          />
          {!isToday && (
            <button type="button" className="btn btn-small" onClick={() => setDate(todayISO())}>
              回到今天
            </button>
          )}
        </label>
      </div>

      <div className="tiles">
        <StatTile label={isToday ? '今日課程數' : '當日課程數'} value={stats.data?.todayCourseCount ?? '—'} unit="堂" hint="GET /coaches/dashboard" />
        <StatTile label={isToday ? '今日學員數' : '當日學員數'} value={stats.data?.todayStudentCount ?? '—'} unit="位" hint="不重複學員" />
        <StatTile
          label="下一堂"
          value={next ? fmtTime(next.starttime) : today.data ? '—' : '…'}
          hint={next ? `${next.studentname}・${next.coursename}` : !isToday ? '只在查看今天時顯示' : today.data ? '今日課程已全部結束' : undefined}
        />
        <StatTile
          label="全館預約率"
          value={gym.data ? fmtPercent(booked + open ? booked / (booked + open) : 0) : '—'}
          hint="已預約 ÷（已預約＋可預約）"
        />
      </div>

      <Card title="今日教學課表" subtitle={`${fmtMonthDay(date)}・GET /coaches/schedules`}>
        {notice && (
          <p className={`notice notice-${notice.tone}`} role="status">
            {notice.text}
          </p>
        )}
        <AsyncView state={today} minHeight={200}>
          {() =>
            sorted.length ? (
              <div className="table-wrap">
                <table className="table table-lg">
                  <thead>
                    <tr>
                      <th>時間</th>
                      <th>課程名稱</th>
                      <th>學生名稱</th>
                      <th>狀態</th>
                      <th>操作</th>
                    </tr>
                  </thead>
                  <tbody>
                    {sorted.map((r) => {
                      const start = toDateTime(date, r.starttime);
                      const end = toDateTime(date, r.endtime);
                      const state = now >= end ? 'past' : now >= start ? 'live' : next?.scheduleid === r.scheduleid ? 'next' : 'todo';
                      return (
                        <tr key={r.bookingid ?? r.scheduleid} className={`row-${state}`}>
                          <td>{fmtTimeRange(r.starttime, r.endtime)}</td>
                          <td>{r.coursename}</td>
                          <td>{r.studentname}</td>
                          <td>
                            <span className={`tag tag-${state}`}>
                              {{ past: '已結束', live: '進行中', next: '下一堂', todo: '待上課' }[state]}
                            </span>
                          </td>
                          <td>
                            {state === 'past' ? (
                              <span className="muted small">—</span>
                            ) : (
                              <button
                                type="button"
                                className="btn btn-small btn-danger"
                                disabled={busyId !== undefined}
                                onClick={() => void cancel(r)}
                              >
                                {busyId === r.bookingid ? '取消中…' : '代取消'}
                              </button>
                            )}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            ) : (
              <p className="muted">{isToday ? '今天沒有學員預約' : '這天沒有學員預約'}</p>
            )
          }
        </AsyncView>
      </Card>

      <Card title="全館教練排課表" subtitle={`${fmtMonthDay(date)}・你的時段加框`} action={<ScheduleLegend />}>
        <AsyncView state={gym} minHeight={360}>
          {(rows) => (
            <ScheduleGrid rows={rows} highlightCoachId={rows.find((r) => r.coachname === user?.name)?.coachid} />
          )}
        </AsyncView>
      </Card>
    </div>
  );
}
