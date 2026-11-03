import { Fragment, useEffect, useState } from 'react';
import { api, useApi } from '../../api/dashboard';
import { useCountUp } from '../../components/motion';
import { SHOW_MOCK, mockCoachProfile, mockCoachSchedule } from '../../mocks/dashboardMock';
import { fmtMonthDay, fmtTime, todayISO, toDateTime } from '../../utils/format';
import '../dashboard.css';

/** 每分鐘更新一次「現在」 */
function useNow() {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 60_000);
    return () => clearInterval(id);
  }, []);
  return now;
}

const hhmm = (d: Date) => `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;

/** 教練首頁：當日計分條＋時間軸課表（GET /api/coach/schedules/mine?date=）。SHOW_MOCK 為 true 時顯示假資料。 */
export default function TrainerPage() {
  const [date, setDate] = useState(todayISO);
  const isToday = date === todayISO();
  const now = useNow();

  const scheduleQ = useApi(() => api.mySchedule(date), [date], !SHOW_MOCK);
  const profileQ = useApi(api.coachProfile, [], !SHOW_MOCK);
  const coach = SHOW_MOCK ? mockCoachProfile : profileQ.data;
  const rows = (SHOW_MOCK ? mockCoachSchedule(date) : scheduleQ.data) ?? [];
  const loaded = SHOW_MOCK || scheduleQ.data !== undefined;
  // 有學員的時段（已預約或已上完）才算一堂課
  const classes = rows.filter((r) => r.membername);
  const students = new Set(classes.map((r) => r.membername)).size;
  const start = (r: (typeof rows)[number]) => toDateTime(r.classdate, r.starttime);
  const end = (r: (typeof rows)[number]) => toDateTime(r.classdate, r.endtime);
  const next = classes.find((r) => r.status === 'booked' && start(r) > now);
  const nowIndex = isToday ? rows.findIndex((r) => start(r) > now) : -1;
  const showNow = isToday && rows.length > 0;
  const err = scheduleQ.error;

  const classN = useCountUp(loaded ? classes.length : null, { delay: 200 });
  const studentN = useCountUp(loaded ? students : null, { delay: 280 });

  const nowLine = (
    <li className="now-line" aria-label={`現在 ${hhmm(now)}`}>
      <span>現在 {hhmm(now)}</span>
      <i />
    </li>
  );

  return (
    <div className="dash">
      <header className="dash-head">
        {/* 教練身分：頭像（姓名第一個字）＋姓名、編號、日期＋專長 */}
        <div className="coach-id">
          <div className="coach-avatar" aria-hidden>
            {coach?.name.slice(0, 1) ?? ''}
          </div>
          <div className="coach-text">
            <h1 className="coach-line">
              <b>{coach ? `${coach.name} 教練` : '教練'}</b>
              {coach && <span className="coach-no">{coach.coachno}</span>}
              <span className="coach-date">
                {fmtMonthDay(date)}
                {isToday ? ' 今天' : ''}
              </span>
            </h1>
            {coach?.specialty && <p className="coach-spec">專長：{coach.specialty}</p>}
          </div>
        </div>
        <label className="dash-date">
          查看日期
          <input type="date" value={date} min="2000-01-01" max="2099-12-31" onChange={(e) => e.target.value && setDate(e.target.value)} />
          {!isToday && (
            <button type="button" className="dash-link" onClick={() => setDate(todayISO())}>
              回到今天
            </button>
          )}
        </label>
      </header>

      {/* 主視覺：當天計分條 */}
      <section className="d-hero score" aria-label="當天概況">
        <div className="score-item">
          <small>{isToday ? '今天要上' : '這天要上'}</small>
          <b>
            {classN}
            <em>堂課</em>
          </b>
        </div>
        <div className="score-item">
          <small>學員</small>
          <b>
            {studentN}
            <em>位</em>
          </b>
        </div>
        <div className="score-item is-next">
          <small>下一堂</small>
          <b>{next ? fmtTime(next.starttime) : '—'}</b>
          <span className="sub">
            {next ? `${next.coursename}，${next.membername}` : loaded ? (classes.length ? '這天的課都上完了' : '這天沒有學員預約') : ''}
          </span>
        </div>
      </section>

      <section className="panel" aria-labelledby="tl-title">
        <div className="panel-head">
          <h2 id="tl-title">{isToday ? '今日教學課表' : `${fmtMonthDay(date)} 教學課表`}</h2>
          <span className="tl-slot-course">空堂可以讓學員預約</span>
        </div>

        {err?.status === 401 ? (
          <p className="auth-note" role="alert">
            還沒登入，看不到課表。請先登入教練帳號（測試時可用 POST /api/test/login）。
          </p>
        ) : err?.status === 403 ? (
          <p className="auth-note" role="alert">
            目前登入的是學員帳號，教練首頁要用教練帳號登入。
          </p>
        ) : err ? (
          <p className="load-error" role="alert">
            {err.message}
            <button type="button" className="dash-link" onClick={scheduleQ.reload}>
              重新載入
            </button>
          </p>
        ) : !loaded ? (
          <p className="empty-note">載入中…</p>
        ) : rows.length === 0 ? (
          <p className="empty-note">這天沒有排課</p>
        ) : (
          // key 跟著日期：換日期時課表重新進場
          <ol className="timeline" key={date}>
            {rows.map((r, i) => {
              const done = end(r) <= now;
              const live = start(r) <= now && end(r) > now;
              const taken = !!r.membername;
              const cls = [
                'tl-slot',
                taken ? 'is-booked' : 'is-open',
                done ? 'is-done' : '',
                live ? 'is-now' : '',
              ].join(' ');
              return (
                <Fragment key={r.scheduleid}>
                  {showNow && i === nowIndex && !live && nowLine}
                  <li className={cls} style={{ ['--i' as string]: i }}>
                    <div className="tl-slot-time">
                      {fmtTime(r.starttime)}
                      <small>到 {fmtTime(r.endtime)}</small>
                    </div>
                    <div className="tl-slot-body">
                      {taken ? (
                        <>
                          <div>
                            <div className="tl-slot-student">{r.membername}</div>
                            <div className="tl-slot-course">{r.coursename}</div>
                          </div>
                          <span className="tl-slot-tag">
                            {live ? '上課中' : r.status === 'completed' ? '已完成' : done ? '已結束' : '已預約'}
                          </span>
                          {!done && r.status === 'booked' && (
                            <div className="tl-slot-actions">
                              <button type="button">改期</button>
                              <button type="button" className="danger">
                                取消
                              </button>
                            </div>
                          )}
                        </>
                      ) : (
                        <span>{r.status === 'available' ? '空堂，尚無學員預約' : done ? '空堂，沒有學員預約' : '這個時段不開放預約'}</span>
                      )}
                    </div>
                  </li>
                </Fragment>
              );
            })}
            {showNow && nowIndex === -1 && nowLine}
          </ol>
        )}
      </section>
    </div>
  );
}
