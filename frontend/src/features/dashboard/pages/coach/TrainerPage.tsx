import { useEffect, useState } from 'react';
import { Link } from 'react-router';
import { request } from '../../../../api.js';
import { Card, StatTile, StatusPill } from '../../components/ui';
import { fmtMonthDay, todayISO } from '../../utils/format';
import './TrainerPage.css';

type Dashboard = { todayCourseCount: number; todayStudentCount: number };
type Schedule = {
  bookingid: number;
  scheduleid: number;
  coursename: string | null;
  studentname: string | null;
  starttime: string;
  endtime: string;
};
type GymSchedule = {
  scheduleid: number;
  coachid: number;
  coachname: string | null;
  coursename: string | null;
  membername: string | null;
  starttime: string;
  endtime: string;
  status: string;
};

const nonnegativeInteger = (value: unknown) => Number.isInteger(value) && Number(value) >= 0;
function isDashboard(value: unknown): value is Dashboard {
  const data = value as Dashboard | null;
  return data != null && nonnegativeInteger(data.todayCourseCount) && nonnegativeInteger(data.todayStudentCount);
}
function isSchedules(value: unknown): value is Schedule[] {
  return Array.isArray(value) && value.every(item => item && Number.isInteger(item.bookingid)
    && typeof item.starttime === 'string' && typeof item.endtime === 'string');
}
function isGymSchedules(value: unknown): value is GymSchedule[] {
  return Array.isArray(value) && value.every(item => item && Number.isInteger(item.scheduleid)
    && Number.isInteger(item.coachid) && typeof item.starttime === 'string'
    && typeof item.endtime === 'string' && typeof item.status === 'string');
}

// Each card loads independently; an unavailable endpoint must not look like an empty day.
function useCoachResource<T>(url: string, validate: (value: unknown) => value is T, attempt: number) {
  const key = `${url}#${attempt}`;
  const [result, setResult] = useState<{ key: string; data: T | null; error: string }>({ key: '', data: null, error: '' });
  useEffect(() => {
    const controller = new AbortController();
    request(url, { signal: controller.signal })
      .then((data) => {
        if (controller.signal.aborted) return;
        if (!validate(data)) throw new Error('課表回傳格式不正確，請確認後端版本。');
        setResult({ key, data, error: '' });
      })
      .catch((failure: unknown) => {
        if (controller.signal.aborted) return;
        setResult({ key, data: null, error: failure instanceof Error ? failure.message : '資料讀取失敗' });
      });
    return () => controller.abort();
  }, [url, validate, attempt]);
  return { data: result.key === key ? result.data : null, error: result.key === key ? result.error : '', loading: result.key !== key };
}

const clock = (date: string, time: string) => Date.parse(`${date}T${time}+08:00`);
const timeRange = (row: { starttime: string; endtime: string }) => `${row.starttime.slice(0, 5)}–${row.endtime.slice(0, 5)}`;
function timeStatus(date: string, row: Schedule, now: number) {
  if (clock(date, row.endtime) <= now) return '已結束';
  if (clock(date, row.starttime) <= now) return '進行中';
  return '未開始';
}

export default function TrainerPage({ coachName = '' }: { coachName?: string }) {
  const [date, setDate] = useState(todayISO);
  const [attempt, setAttempt] = useState(0);
  const [now, setNow] = useState(Date.now);
  const isToday = date === todayISO();
  const query = `?date=${encodeURIComponent(date)}`;
  const dashboard = useCoachResource(`/api/coach/dashboard${query}`, isDashboard, attempt);
  const own = useCoachResource(`/api/coach/schedules${query}`, isSchedules, attempt);
  const gym = useCoachResource(`/api/coach/schedules/gym${query}`, isGymSchedules, attempt);
  const schedules = [...(own.data ?? [])].sort((a, b) => a.starttime.localeCompare(b.starttime));
  const gymSchedules = [...(gym.data ?? [])].sort((a, b) => a.starttime.localeCompare(b.starttime) || a.coachid - b.coachid);
  const next = schedules.find(row => clock(date, row.starttime) >= now);
  const refreshing = dashboard.loading || own.loading || gym.loading;
  const reload = () => { setNow(Date.now()); setAttempt(value => value + 1); };

  useEffect(() => {
    const timer = setInterval(() => setNow(Date.now()), 30000);
    return () => clearInterval(timer);
  }, []);

  return <div className="page trainer-home">
    <div className="page-head">
      <div><h1>教練首頁</h1>{coachName && <p className="muted">你好，{coachName}教練</p>}</div>
      <div className="trainer-controls">
        <label className="date-picker">查看日期
          <input type="date" value={date} min="2000-01-01" max="2099-12-31"
            onChange={event => { if (event.target.value) { setDate(event.target.value); setNow(Date.now()); } }} />
        </label>
        {!isToday && <button type="button" className="btn btn-small" onClick={() => { setDate(todayISO()); setNow(Date.now()); }}>回到今天</button>}
        <button type="button" className="btn" disabled={refreshing} onClick={reload}>重新讀取</button>
      </div>
    </div>

    <div className="tiles" aria-busy={dashboard.loading || own.loading}>
      <StatTile label={isToday ? '今日課程數' : '當日課程數'} value={dashboard.data?.todayCourseCount ?? '—'} unit="堂" />
      <StatTile label={isToday ? '今日學員數' : '當日學員數'} value={dashboard.data?.todayStudentCount ?? '—'} unit="位" hint="不重複學員" />
      <StatTile label={isToday ? '下一堂' : '當日下一堂'}
        value={own.loading ? '載入中' : own.error ? '—' : next?.starttime.slice(0, 5) ?? '—'}
        hint={next ? `${next.coursename ?? '課程'}・${next.studentname ?? '學員'}` : own.loading || own.error ? undefined : '當日沒有尚未開始的預約'} />
    </div>
    {dashboard.error && <p className="notice trainer-error" role="alert">當日統計讀取失敗：{dashboard.error} <button type="button" className="btn btn-small" onClick={reload}>重試</button></p>}

    <Card title={isToday ? '今日教學課表' : '當日教學課表'} subtitle={`${date}・${fmtMonthDay(date)}`}
      action={<Link to="/schedule" className="btn">管理我的預約</Link>}>
      {own.loading ? <p className="trainer-state" role="status">教學課表載入中…</p> :
        own.error ? <p className="trainer-state trainer-error" role="alert">教學課表讀取失敗：{own.error} <button type="button" className="btn btn-small" onClick={reload}>重試</button></p> :
          !schedules.length ? <p className="trainer-state muted">這一天沒有學員預約。</p> :
            <div className="table-wrap trainer-table-wrap"><table className="table trainer-table">
              <caption className="trainer-table-caption">{date} 自己的已預約教學課表</caption>
              <thead><tr><th scope="col">時間</th><th scope="col">課程名稱</th><th scope="col">學員姓名</th><th scope="col">時段狀態</th></tr></thead>
              <tbody>{schedules.map(row => <tr key={row.bookingid}>
                <td className="trainer-time">{timeRange(row)}</td><td>{row.coursename ?? '—'}</td><td>{row.studentname ?? '—'}</td>
                <td><span className="pill">{timeStatus(date, row, now)}</span></td>
              </tr>)}</tbody>
            </table></div>}
    </Card>

    <Card title="全館教練排課表" subtitle={`${date}・包含其他教練及尚未被預約的時段`}>
      {gym.loading ? <p className="trainer-state" role="status">全館排課載入中…</p> :
        gym.error ? <p className="trainer-state trainer-error" role="alert">全館排課讀取失敗：{gym.error} <button type="button" className="btn btn-small" onClick={reload}>重試</button></p> :
          !gymSchedules.length ? <p className="trainer-state muted">這一天沒有全館排課資料。</p> :
            <div className="table-wrap trainer-table-wrap"><table className="table trainer-table">
              <caption className="trainer-table-caption">{date} 全館教練排課</caption>
              <thead><tr><th scope="col">時間</th><th scope="col">教練</th><th scope="col">課程</th><th scope="col">預約會員</th><th scope="col">排課狀態</th></tr></thead>
              <tbody>{gymSchedules.map(row => <tr key={row.scheduleid}>
                <td className="trainer-time">{timeRange(row)}</td><td>{row.coachname ?? `教練 ${row.coachid}`}</td>
                <td>{row.coursename ?? '—'}</td><td>{row.membername ?? '—'}</td><td><StatusPill status={row.status} /></td>
              </tr>)}</tbody>
            </table></div>}
    </Card>
  </div>;
}
