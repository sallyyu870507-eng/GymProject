import { Link } from 'react-router-dom';
import { memberApi } from '../../api/member';
import { useAuth } from '../../auth/AuthContext';
import { AttendanceChart, InBodyChart } from '../../components/charts';
import { CourseProgress, MemberAvatar, NextClassSummary } from '../../components/member';
import { AsyncView, Card, StatusPill } from '../../components/ui';
import { useApi, useNow } from '../../hooks/useApi';
import { fmtDate } from '../../utils/format';
import { INBODY_METRICS, metricValue, summarizeInBody, upcomingBookings, type InBodyMetric } from '../../utils/stats';

/** 學員首頁：依 Figma 線框稿（下一堂課 + 2×2 卡片） */
export default function StudentHome() {
  const { user } = useAuth();
  const now = useNow();
  const bookings = useApi((s) => memberApi.bookings(s), []);
  const profile = useApi((s) => memberApi.profile(s), []);
  const courses = useApi((s) => memberApi.courses(s), []);
  const inbody = useApi((s) => memberApi.inbody(s), []);
  const attendance = useApi((s) => memberApi.attendance(s), []);

  return (
    <div className="page">
      <h1 className="hello">你好，{user?.name} 學員</h1>

      <section className="card next-bar">
        <h2>下一堂課</h2>
        <AsyncView state={bookings} minHeight={88}>
          {(list) => <NextClassSummary booking={upcomingBookings(list, now)[0]} now={now} />}
        </AsyncView>
        <Link to="/student/remind" className="btn btn-lg">
          查看課程
        </Link>
      </section>

      <div className="grid-2">
        <Card title="會員管理" footer={<Link to="/student/profile" className="btn">查看資料</Link>}>
          <AsyncView state={profile} minHeight={128}>
            {(m) => (
              <div className="member-summary">
                <MemberAvatar name={m.name} url={m.avatarurl} />
                <dl className="meta">
                  <dt>姓名</dt>
                  <dd>{m.name}</dd>
                  <dt>會員編號</dt>
                  <dd>{m.memberno}</dd>
                  <dt>手機</dt>
                  <dd>{m.phone}</dd>
                  <dt>生日</dt>
                  <dd>{fmtDate(m.birthday)}</dd>
                  <dt>狀態</dt>
                  <dd>
                    <StatusPill status={m.status} />
                  </dd>
                </dl>
              </div>
            )}
          </AsyncView>
        </Card>

        <Card title="INBODY 分析" footer={<Link to="/student/inbody" className="btn">查看分析</Link>}>
          <AsyncView state={inbody} minHeight={240}>
            {(rows) => {
              const s = summarizeInBody(rows);
              return (
                <>
                  <div className="mini-stats">
                    {(['weight', 'musclemass', 'bodyfatpct', 'fatmass'] as InBodyMetric[]).map((m) => (
                      <div key={m}>
                        <b>{s.latest ? metricValue(s.latest, m).toFixed(1) : '—'}</b>
                        <span>
                          {INBODY_METRICS[m].label} {INBODY_METRICS[m].unit}
                        </span>
                      </div>
                    ))}
                  </div>
                  <div className="well">
                    <InBodyChart rows={rows} metrics={['weight', 'musclemass']} height={170} />
                  </div>
                </>
              );
            }}
          </AsyncView>
        </Card>

        <Card title="課程管理" footer={<Link to="/student/courses" className="btn">查看課程</Link>}>
          <AsyncView state={courses} minHeight={140}>
            {(list) =>
              list.length ? (
                <div className="well course-list">
                  {list.map((c) => (
                    <CourseProgress key={c.membercourseid} course={c} compact />
                  ))}
                </div>
              ) : (
                <p className="muted">目前沒有有效課程</p>
              )
            }
          </AsyncView>
        </Card>

        <Card title="出席紀錄" footer={<Link to="/student/bookings" className="btn">查看預約</Link>}>
          <AsyncView state={attendance} minHeight={200}>
            {(weeks) => {
              const total = weeks.reduce((sum, w) => sum + w.checkins, 0);
              const done = bookings.data?.filter((b) => b.bookingstatus === 'completed').length;
              const cancelled = bookings.data?.filter((b) => b.bookingstatus === 'cancelled').length;
              return (
                <>
                  <div className="mini-stats">
                    <div>
                      <b>{total}</b>
                      <span>近 {weeks.length} 週到館</span>
                    </div>
                    <div>
                      <b>{done ?? '—'}</b>
                      <span>已完成課程</span>
                    </div>
                    <div>
                      <b>{cancelled ?? '—'}</b>
                      <span>已取消</span>
                    </div>
                  </div>
                  <AttendanceChart rows={weeks} height={160} />
                </>
              );
            }}
          </AsyncView>
        </Card>
      </div>
    </div>
  );
}
