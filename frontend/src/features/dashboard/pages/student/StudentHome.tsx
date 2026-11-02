import { useEffect, useState } from 'react';
import { request } from '../../../../api.js';
import { Card } from '../../components/ui';
import { todayISO } from '../../utils/format';
import InBodyCard from './InBodyCard';
import AttendanceCard from './AttendanceCard';
import PurchasedCoursesCard from './PurchasedCoursesCard';
import NextClassBanner from './NextClassBanner';

type MemberProfile = {
  memberid: number;
  memberno: string;
  name: string;
  phone: string | null;
  birthday: string | null;
  status: string;
};

/** 學員首頁：依 Figma 線框稿（下一堂課 + 2×2 卡片） */
export default function StudentHome() {
  const [date, setDate] = useState(todayISO);
  const isToday = date === todayISO();

  const [profile, setProfile] = useState<MemberProfile | null>(null);
  const [profileLoading, setProfileLoading] = useState(true);
  const [profileError, setProfileError] = useState('');
  const [profileAttempt, setProfileAttempt] = useState(0);

  useEffect(() => {
    const controller = new AbortController();

    setProfileLoading(true);
    setProfileError('');

    request('/api/member/profile', { signal: controller.signal })
      .then((data) => {
        if (!controller.signal.aborted) setProfile(data);
      })
      .catch((error: unknown) => {
        if (controller.signal.aborted) return;
        setProfile(null);
        setProfileError(
          error instanceof Error ? error.message : '會員資料讀取失敗',
        );
      })
      .finally(() => {
        if (!controller.signal.aborted) setProfileLoading(false);
      });

    return () => controller.abort();
  }, [profileAttempt]);
  
  return (
    <div className="page">
      <div className="page-head">
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
{/*下一堂課區*/}
      <NextClassBanner fromDate={date} />
	  
      <div className="grid-2">
	  <Card
	    title="會員管理"
	    footer={
	      <button
	        type="button"
	        className="btn"
	        disabled={profileLoading}
	        onClick={() => setProfileAttempt((value) => value + 1)}
	      >
	        重新讀取
	      </button>
	    }
	  >
	    {profileLoading ? (
	      <p role="status">會員資料載入中…</p>
	    ) : profileError ? (
	      <p role="alert">{profileError}</p>
	    ) : profile ? (
	      <div className="member-summary">
			<div className="avatar avatar-empty" aria-hidden="true" />
	        <dl className="meta">
	          <dt>姓名</dt>
	          <dd>{profile.name || '—'}</dd>

	          <dt>會員編號</dt>
	          <dd>{profile.memberno || '—'}</dd>

	          <dt>手機</dt>
	          <dd>{profile.phone || '—'}</dd>

	          <dt>生日</dt>
	          <dd>{profile.birthday || '—'}</dd>

	          <dt>狀態</dt>
	          <dd>
	            {profile.status === 'active'
	              ? '啟用'
	              : profile.status === 'inactive'
	                ? '停用'
	                : profile.status || '—'}
	          </dd>
	        </dl>
	      </div>
	    ) : null}
	  </Card>

		<InBodyCard />

      	<PurchasedCoursesCard />

		<AttendanceCard />
      </div>
    </div>
  );
}
