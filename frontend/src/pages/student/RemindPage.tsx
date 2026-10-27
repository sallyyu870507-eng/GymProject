import type { ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { memberApi } from '../../api/member';
import type { InBodyRecord, MemberCourse } from '../../api/types';
import { AsyncView, Card, PageHeader } from '../../components/ui';
import { useApi, useNow } from '../../hooks/useApi';
import { fmtDate, fmtMonthDay, fmtTimeRange, parseDate, toDateTime, todayISO } from '../../utils/format';
import { upcomingBookings } from '../../utils/stats';

const INBODY_INTERVAL_DAYS = 28;

export default function RemindPage() {
  const now = useNow();
  const bookings = useApi((s) => memberApi.bookings(s), []);
  const courses = useApi((s) => memberApi.courses(s), []);
  const inbody = useApi((s) => memberApi.inbody(s), []);

  return (
    <div className="page">
      <PageHeader title="課堂提醒" />

      <Card title="下一堂課" subtitle="依目前時間自動判斷">
        <AsyncView state={bookings} minHeight={140}>
          {(list) => {
            const next = upcomingBookings(list, now)[0];
            if (!next) {
              return (
                <p className="muted">
                  目前沒有已預約的課程，<Link to="/student/bookings/new">去預約</Link>
                </p>
              );
            }
            const mins = Math.max(0, Math.floor((toDateTime(next.classdate, next.starttime).getTime() - now.getTime()) / 60_000));
            return (
              <div className="hero">
                <div>
                  <div className="hero-title">{next.coursename}</div>
                  <dl className="meta">
                    <dt>日期</dt>
                    <dd>{fmtMonthDay(next.classdate)}</dd>
                    <dt>時間</dt>
                    <dd>{fmtTimeRange(next.starttime, next.endtime)}</dd>
                    <dt>教練</dt>
                    <dd>{next.coachname}</dd>
                    <dt>教室</dt>
                    <dd>{next.classroom}</dd>
                  </dl>
                </div>
                <div>
                  <p className="muted small">{mins > 0 ? '距離開課' : '課程進行中'}</p>
                  <div className="countdown">
                    {[
                      [Math.floor(mins / 1440), '天'],
                      [Math.floor((mins % 1440) / 60), '時'],
                      [mins % 60, '分'],
                    ].map(([v, u]) => (
                      <div key={u}>
                        <b>{v}</b>
                        <span>{u}</span>
                      </div>
                    ))}
                  </div>
                  <p className="muted small">請提前 10 分鐘到場暖身，取消請於 24 小時前完成</p>
                </div>
              </div>
            );
          }}
        </AsyncView>
      </Card>

      <div className="grid-2">
        <Card title="提醒事項" subtitle="堂數不足、InBody 回測">
          <Alerts courses={courses.data} inbody={inbody.data} loading={!courses.data || !inbody.data} />
        </Card>

        <Card title="未來 14 天課程" subtitle="只列出狀態為「已預約」的課">
          <AsyncView state={bookings} minHeight={160}>
            {(list) => {
              const limit = new Date(now);
              limit.setDate(limit.getDate() + 14);
              const rows = upcomingBookings(list, now).filter((b) => toDateTime(b.classdate, b.starttime) <= limit);
              if (!rows.length) return <p className="muted">未來 14 天沒有預約</p>;
              return (
                <div className="table-wrap">
                  <table className="table">
                    <thead>
                      <tr>
                        <th>日期</th>
                        <th>時間</th>
                        <th>課程</th>
                        <th>教練</th>
                        <th>教室</th>
                      </tr>
                    </thead>
                    <tbody>
                      {rows.map((b) => (
                        <tr key={b.bookingid}>
                          <td>{fmtMonthDay(b.classdate)}</td>
                          <td>{fmtTimeRange(b.starttime, b.endtime)}</td>
                          <td>{b.coursename}</td>
                          <td>{b.coachname}</td>
                          <td>{b.classroom}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              );
            }}
          </AsyncView>
        </Card>
      </div>
    </div>
  );
}

function Alerts({
  courses,
  inbody,
  loading,
}: {
  courses?: MemberCourse[];
  inbody?: InBodyRecord[];
  loading: boolean;
}) {
  if (loading) return <div className="skeleton" style={{ minHeight: 140 }} />;
  const items: { tone: 'bad' | 'warn' | 'ok'; title: ReactNode; sub: ReactNode; order: number }[] = [];

  for (const c of courses ?? []) {
    if (c.remainingsessions > 2) continue;
    items.push({
      tone: 'warn',
      title: `${c.coursename} 只剩 ${c.remainingsessions} 堂`,
      sub: `教練 ${c.coachname}・共 ${c.totalsessions ?? '—'} 堂，記得續約`,
      order: 1,
    });
  }

  const last = [...(inbody ?? [])].sort((a, b) => b.recorddate.localeCompare(a.recorddate))[0];
  if (last) {
    const since = Math.round((parseDate(todayISO()).getTime() - parseDate(last.recorddate).getTime()) / 86_400_000);
    const due = since >= INBODY_INTERVAL_DAYS;
    items.push({
      tone: due ? 'warn' : 'ok',
      title: due ? `距上次 InBody 已 ${since} 天，建議回測` : `下次 InBody 建議在 ${INBODY_INTERVAL_DAYS - since} 天後`,
      sub: `上次檢測 ${fmtDate(last.recorddate)}，建議每 4 週一次`,
      order: 2,
    });
  }

  return (
    <ul className="alerts">
      {items
        .sort((a, b) => a.order - b.order)
        .map((item, i) => (
          <li key={i}>
            <i className={`dot dot-${item.tone}`} />
            <div>
              <div>{item.title}</div>
              <div className="muted small">{item.sub}</div>
            </div>
          </li>
        ))}
    </ul>
  );
}
