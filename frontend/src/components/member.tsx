import { useState } from 'react';
import { Link } from 'react-router-dom';
import type { BookingResult, MemberCourse } from '../api/types';
import { fmtDate, fmtDuration, fmtMonthDay, fmtTimeRange, toDateTime } from '../utils/format';
import { ProgressBar } from './ui';

/** 會員照片（member.avatarurl）；沒有照片或圖檔讀不到時，顯示姓名後兩字 */
export function MemberAvatar({ name, url }: { name: string; url?: string | null }) {
  const [broken, setBroken] = useState(false);
  if (url && !broken) {
    return <img className="avatar" src={url} alt={`${name} 的照片`} onError={() => setBroken(true)} />;
  }
  return (
    <div className="avatar" aria-hidden>
      {name.slice(-2)}
    </div>
  );
}

/** 首頁「下一堂課」那一列的文字 */
export function NextClassSummary({ booking, now }: { booking?: BookingResult; now: Date }) {
  if (!booking) {
    return (
      <p className="muted">
        目前沒有已預約的課程，<Link to="/student/bookings/new">馬上預約</Link>
      </p>
    );
  }
  const ms = toDateTime(booking.classdate, booking.starttime).getTime() - now.getTime();
  return (
    <div className="next-info">
      <div className="next-when">
        {fmtMonthDay(booking.classdate)} {fmtTimeRange(booking.starttime, booking.endtime)}
      </div>
      <div>
        <b>{booking.coursename}</b>・{booking.classroom}
      </div>
      <div>教練：{booking.coachname}</div>
      <div className="next-countdown">{ms > 0 ? `還有 ${fmtDuration(ms)}開課` : '課程進行中'}</div>
    </div>
  );
}

/** 課程剩餘堂數＋進度條（首頁與課程管理共用） */
export function CourseProgress({ course, compact }: { course: MemberCourse; compact?: boolean }) {
  const total = course.totalsessions ?? course.remainingsessions;
  const used = total - course.remainingsessions;
  const low = course.remainingsessions <= 2;
  return (
    <div className={compact ? 'course-row' : 'course-card'}>
      <div className="course-top">
        <span className="course-name">{course.coursename}</span>
        <span className="muted small">{course.coachname}</span>
      </div>
      <div className="course-count">
        {compact ? (
          <span className="muted small">
            剩 <b className={low ? 'tone-warn' : undefined}>{course.remainingsessions}</b>
            {course.totalsessions !== undefined && ` / ${course.totalsessions}`} 堂
          </span>
        ) : (
          <>
            <b className={`big-num ${low ? 'tone-warn' : ''}`}>{course.remainingsessions}</b>
            <span className="muted small">
              {course.totalsessions !== undefined ? `/ ${course.totalsessions} 堂剩餘` : '堂剩餘'}
            </span>
          </>
        )}
      </div>
      {course.totalsessions !== undefined && (
        <ProgressBar ratio={total ? used / total : 0} tone={low ? 'bad' : undefined} />
      )}
      {!compact && (
        <div className="course-foot">
          <span className="muted small">
            已上 {used} 堂{course.purchasedate && `・購買日 ${fmtDate(course.purchasedate)}`}
          </span>
          <Link className="btn btn-small" to={`/student/bookings/new?course=${course.membercourseid}`}>
            預約這門課
          </Link>
        </div>
      )}
    </div>
  );
}
