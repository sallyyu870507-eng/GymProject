import { useEffect, useId, useState } from 'react';
import { Link } from 'react-router-dom';
import { ApiError, api, shrinkImage, useApi } from '../../api/dashboard';
import type { Loaded } from '../../api/dashboard';
import { SessionRing, TrendLines, WeeklyBars } from '../../components/MiniCharts';
import { useCountUp } from '../../components/motion';
import {
  SHOW_MOCK,
  mockAttendance,
  mockBookingStats,
  mockCourses,
  mockInBody,
  mockNextClass,
  mockProfile,
} from '../../mocks/dashboardMock';
import { daysUntil, fmtDate, fmtMonthDay, fmtTime, todayISO } from '../../utils/format';
import '../dashboard.css';

const STATUS: Record<string, string> = { active: '有效會員', inactive: '已停用' };

/** 假資料模式直接用假資料；否則用 API 的結果 */
function pick<T>(mock: T, loaded: Loaded<T>): T | undefined {
  return SHOW_MOCK ? mock : loaded.data;
}

/** 卡片裡的錯誤訊息＋重試（401 由頁面上方統一提示，這裡不重複） */
function LoadError({ error, onRetry }: { error?: ApiError; onRetry: () => void }) {
  if (!error || error.status === 401) return null;
  return (
    <p className="load-error" role="alert">
      {error.message}
      <button type="button" className="dash-link" onClick={onRetry}>
        重新載入
      </button>
    </p>
  );
}

/**
 * 會員照片：有 avatarurl 就顯示照片，沒有就顯示姓氏。
 * 點照片選一張圖片：先縮小再上傳到 POST /api/member/avatar，成功後換成新照片。
 * 假資料模式只在瀏覽器預覽，不上傳。
 */
function MemberPhoto({ name, url, onUploaded }: { name?: string; url: string | null; onUploaded: (url: string) => void }) {
  const [preview, setPreview] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const id = useId();
  useEffect(
    () => () => {
      if (preview) URL.revokeObjectURL(preview);
    },
    [preview],
  );

  async function choose(file: File) {
    setError(null);
    if (!file.type.startsWith('image/')) {
      setError('請選擇圖片檔');
      return;
    }
    setPreview(URL.createObjectURL(file));
    if (SHOW_MOCK) return;
    setBusy(true);
    try {
      const res = await api.uploadAvatar(await shrinkImage(file));
      onUploaded(res.avatarurl);
      setPreview(null);
    } catch (e) {
      setPreview(null);
      setError(e instanceof ApiError ? e.message : '照片上傳失敗，請再試一次');
    } finally {
      setBusy(false);
    }
  }

  const src = preview ?? url;
  const action = busy ? '上傳中…' : src ? '更換照片' : '上傳照片';
  return (
    <div className="member-photo">
      <input
        id={id}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        className="sr-only"
        disabled={busy}
        onChange={(e) => {
          const f = e.target.files?.[0];
          if (f) void choose(f);
          e.target.value = '';
        }}
      />
      <label htmlFor={id} title={action} className={busy ? 'is-busy' : undefined}>
        {src ? <img src={src} alt={name ? `${name}的照片` : '會員照片'} /> : <span className="photo-initial">{name?.slice(0, 1) ?? ''}</span>}
        <span className="photo-action">{action}</span>
      </label>
      {error && (
        <p className="photo-error" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}

/** 學員首頁：每個區塊各自呼叫一支 API（SHOW_MOCK 為 true 時改用假資料） */
export default function StudentHome() {
  const [date, setDate] = useState(todayISO);
  const isToday = date === todayISO();
  const live = !SHOW_MOCK;

  const profileQ = useApi(api.profile, [], live);
  const nextQ = useApi(api.nextClass, [], live);
  const attendanceQ = useApi(() => api.attendance(12), [], live);
  const inbodyQ = useApi(api.inbody, [], live);
  const coursesQ = useApi(api.courses, [], live);
  const statsQ = useApi(api.bookingStats, [], live);
  const all = [profileQ, nextQ, attendanceQ, inbodyQ, coursesQ, statsQ];
  const needLogin = all.some((q) => q.error?.status === 401);
  const wrongRole = all.some((q) => q.error?.status === 403);

  // 上傳照片後直接換掉，不用重新整理
  const [avatarOverride, setAvatarOverride] = useState<string | null>(null);
  const loadedProfile = pick(mockProfile, profileQ);
  const p = loadedProfile && avatarOverride ? { ...loadedProfile, avatarurl: avatarOverride } : loadedProfile;
  const next = pick(mockNextClass, nextQ) ?? null;
  const stats = pick(mockBookingStats, statsQ);
  const courses = pick(mockCourses, coursesQ) ?? [];
  const weeks = pick(mockAttendance, attendanceQ) ?? [];
  // 圖表只畫體重與肌肉量都有值的量測
  const inbody = (pick(mockInBody, inbodyQ) ?? []).filter(
    (r): r is typeof r & { weight: number; musclemass: number } => r.weight != null && r.musclemass != null,
  );
  const allInbody = pick(mockInBody, inbodyQ) ?? [];
  const latestAny = allInbody[allInbody.length - 1];
  const hasWeeks = weeks.some((w) => w.checkins > 0);
  const visits = weeks.length ? weeks.reduce((s, w) => s + w.checkins, 0) : null;
  const activeWeeks = weeks.filter((w) => w.checkins > 0).length;
  const days = next ? daysUntil(next.classdate) : null;

  const visitsN = useCountUp(visits, { delay: 300 });
  const doneN = useCountUp(stats?.completed, { delay: 380 });
  const cancelN = useCountUp(stats?.cancelled, { delay: 460 });
  const weightN = useCountUp(latestAny?.weight, { decimals: 1, delay: 300 });
  const muscleN = useCountUp(latestAny?.musclemass, { decimals: 1, delay: 380 });
  const fatN = useCountUp(latestAny?.bodyfatpct, { decimals: 1, delay: 460 });
  const daysN = useCountUp(days, { delay: 200, duration: 600 });

  const delta = (a?: number | null, b?: number | null) => (a == null || b == null ? null : +(b - a).toFixed(1));
  const firstAll = allInbody[0];
  const dW = allInbody.length > 1 ? delta(firstAll?.weight, latestAny?.weight) : null;
  const dM = allInbody.length > 1 ? delta(firstAll?.musclemass, latestAny?.musclemass) : null;
  const dF = allInbody.length > 1 ? delta(firstAll?.bodyfatpct, latestAny?.bodyfatpct) : null;
  const signed = (v: number) => (v > 0 ? `+${v}` : `${v}`);

  return (
    <div className="dash">
      <header className="dash-head">
        <h1 className="dash-today">
          <b>{fmtMonthDay(date)}</b>
          {isToday ? '今天' : ''}
        </h1>
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

      {needLogin && (
        <p className="auth-note" role="alert">
          還沒登入，看不到你的資料。請先登入學員帳號（測試時可用 POST /api/test/login）。
        </p>
      )}
      {!needLogin && wrongRole && (
        <p className="auth-note" role="alert">
          目前登入的是教練帳號，學員首頁要用學員帳號登入。
        </p>
      )}

      {/* 主視覺：下一堂課 */}
      <section className="d-hero" aria-label="下一堂課">
        <h2 className="d-hero-label">下一堂課</h2>
        <div>
          <div className="d-hero-time">
            <strong>{next ? fmtTime(next.starttime) : '—'}</strong>
            <span>{next ? `${fmtMonthDay(next.classdate)}　到 ${fmtTime(next.endtime)}` : nextQ.loading ? '載入中' : '還沒有預約'}</span>
          </div>
          <div className="d-hero-detail">
            <span>{next ? next.coursename : '預約一堂課，這裡會顯示時間與教練'}</span>
            {next && <span className="soft">{next.coursetype}</span>}
            {next?.classroom && <span className="soft">{next.classroom}</span>}
            {next && <span className="soft">教練 {next.coachname}</span>}
          </div>
        </div>
        <div className="d-hero-count">
          {days !== null && (
            <>
              <b>{days === 0 ? '今天' : daysN}</b>
              <small>{days === 0 ? '記得準時到場' : '天後上課'}</small>
            </>
          )}
          <div>
            <Link to="/student/remind" className="d-hero-btn">
              {next ? '查看課程' : '預約課程'}
            </Link>
          </div>
        </div>
      </section>

      <div className="dash-grid">
        {/* 會員卡 */}
        <section className="panel" aria-labelledby="me-title">
          <div className="panel-head">
            <h2 id="me-title">會員資料</h2>
            <Link to="/student/profile">編輯資料</Link>
          </div>
          <div className="member-card">
            {p && <span className="state">{STATUS[p.status] ?? p.status}</span>}
            <MemberPhoto name={p?.name} url={p?.avatarurl ?? null} onUploaded={setAvatarOverride} />
            <div className="member-info">
              <div className="name">{p ? p.name : '—'}</div>
              <div className="no">{p ? p.memberno : '—'}</div>
              <dl>
                <dt>手機</dt>
                <dd>{p ? p.phone : '—'}</dd>
                <dt>生日</dt>
                <dd>{p ? fmtDate(p.birthday) : '—'}</dd>
                <dt>信箱</dt>
                <dd>{p ? p.email : '—'}</dd>
              </dl>
            </div>
          </div>
          <LoadError error={profileQ.error} onRetry={profileQ.reload} />
        </section>

        {/* 出席紀錄 */}
        <section className="panel" aria-labelledby="att-title">
          <div className="panel-head">
            <h2 id="att-title">出席紀錄</h2>
            <Link to="/student/bookings">查看預約</Link>
          </div>
          <dl className="figures">
            <div>
              <dt>近 12 週到館</dt>
              <dd>
                {visitsN}
                <small>次</small>
              </dd>
            </div>
            <div>
              <dt>有運動的週數</dt>
              <dd>
                {weeks.length ? activeWeeks : '—'}
                <small>/ 12 週</small>
              </dd>
            </div>
            <div>
              <dt>已完成課程</dt>
              <dd>
                {doneN}
                <small>堂</small>
              </dd>
            </div>
            <div>
              <dt>已取消</dt>
              <dd>
                {cancelN}
                <small>堂</small>
              </dd>
            </div>
          </dl>
          <LoadError error={attendanceQ.error ?? statsQ.error} onRetry={() => (attendanceQ.reload(), statsQ.reload())} />
          {hasWeeks ? (
            <div className="chart-box">
              <WeeklyBars data={weeks} />
            </div>
          ) : (
            !attendanceQ.loading && !attendanceQ.error && <p className="empty-note">上完第一堂課後，這裡會出現每週到館次數</p>
          )}
        </section>

        {/* 課程堂數 */}
        <section className="panel" aria-labelledby="plan-title">
          <div className="panel-head">
            <h2 id="plan-title">剩餘堂數</h2>
            <Link to="/student/courses">查看課程</Link>
          </div>
          <LoadError error={coursesQ.error} onRetry={coursesQ.reload} />
          {courses.length > 0 ? (
            <div className="plans">
              {courses.map((c) => {
                const low = c.remainingsessions <= 2;
                return (
                  <div key={c.membercourseid} className="plan">
                    <SessionRing remaining={c.remainingsessions} total={c.totalsessions} low={low} />
                    <div>
                      <div className="plan-name">{c.coursename}</div>
                      <div className="plan-meta">教練 {c.coachname}</div>
                      {low && <div className="plan-warn">快用完了，記得續約</div>}
                    </div>
                    <div className={`plan-left ${low ? 'is-low' : ''}`}>
                      <b>{c.remainingsessions}</b>/ {c.totalsessions} 堂
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            !coursesQ.loading && !coursesQ.error && <p className="empty-note">購買課程後，這裡會顯示每門課剩下幾堂</p>
          )}
        </section>
        {/* InBody */}
        <section className="panel" aria-labelledby="ib-title">
          <div className="panel-head">
            <h2 id="ib-title">InBody 身體組成</h2>
            <Link to="/student/inbody">查看全部紀錄</Link>
          </div>
          <dl className="figures">
            <div>
              <dt>體重</dt>
              <dd>
                {weightN}
                <small>kg</small>
              </dd>
              {dW !== null && <span className={`delta ${dW <= 0 ? 'delta-good' : 'delta-watch'}`}>{signed(dW)} kg</span>}
            </div>
            <div>
              <dt>肌肉量</dt>
              <dd>
                {muscleN}
                <small>kg</small>
              </dd>
              {dM !== null && <span className={`delta ${dM >= 0 ? 'delta-good' : 'delta-watch'}`}>{signed(dM)} kg</span>}
            </div>
            <div>
              <dt>體脂率</dt>
              <dd>
                {fatN}
                <small>%</small>
              </dd>
              {dF !== null && <span className={`delta ${dF <= 0 ? 'delta-good' : 'delta-watch'}`}>{signed(dF)} %</span>}
            </div>
          </dl>
          <LoadError error={inbodyQ.error} onRetry={inbodyQ.reload} />
          {inbody.length > 1 ? (
            <>
              <div className="legend-line">
                <span>
                  <i style={{ background: 'var(--d-slate)' }} />
                  體重
                </span>
                <span>
                  <i style={{ background: 'var(--d-orange)' }} />
                  肌肉量
                </span>
                <span>變化以 {firstAll && fmtMonthDay(firstAll.recorddate)} 第一次量測為基準</span>
              </div>
              <div className="chart-box">
                <TrendLines data={inbody} />
              </div>
            </>
          ) : (
            !inbodyQ.loading && !inbodyQ.error && <p className="empty-note">量測兩次以上，這裡會畫出體重與肌肉量的變化</p>
          )}
        </section>
      </div>
    </div>
  );
}
