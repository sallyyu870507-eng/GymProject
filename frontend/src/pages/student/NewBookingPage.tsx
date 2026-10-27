import { useEffect, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { bookingApi, memberApi } from '../../api/member';
import type { BookingResult, ScheduleSlot } from '../../api/types';
import { MonthCalendar } from '../../components/MonthCalendar';
import { AsyncView, Card, PageHeader } from '../../components/ui';
import { useApi } from '../../hooks/useApi';
import { fmtMonthDay, fmtTime, fmtTimeRange } from '../../utils/format';

/**
 * 預約流程（規格書 4.1 → 4.2 → 4.3 → 4.4）：
 * 選課程 → 選日期 → 選時段 → 送出 POST /booking
 */
export default function NewBookingPage() {
  const [params] = useSearchParams();
  const initialCourse = Number(params.get('course')) || undefined;

  const [courseId, setCourseId] = useState<number | undefined>(initialCourse);
  const [date, setDate] = useState<string>();
  const [slot, setSlot] = useState<ScheduleSlot>();
  const [note, setNote] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string>();
  const [result, setResult] = useState<BookingResult>();

  const courses = useApi((s) => memberApi.courses(s), [result]);
  const dates = useApi(
    (s) => (courseId ? memberApi.availableDates(courseId, s) : Promise.resolve<string[]>([])),
    [courseId],
  );
  const slots = useApi(
    (s) => (courseId && date ? memberApi.schedules(courseId, date, s) : Promise.resolve<ScheduleSlot[]>([])),
    [courseId, date],
  );

  // 換課程就清掉日期，換日期就清掉時段
  useEffect(() => setDate(undefined), [courseId]);
  useEffect(() => setSlot(undefined), [courseId, date]);

  const course = courses.data?.find((c) => c.membercourseid === courseId);

  const submit = async () => {
    if (!courseId || !slot) return;
    setSubmitting(true);
    setError(undefined);
    try {
      const res = await bookingApi.create({ membercourseid: courseId, scheduleid: slot.scheduleid, note: note.trim() });
      setResult(res);
    } catch (err) {
      setError((err as Error).message);
      slots.reload();
    } finally {
      setSubmitting(false);
    }
  };

  const reset = () => {
    setResult(undefined);
    setSlot(undefined);
    setNote('');
    slots.reload();
  };

  if (result) {
    return (
      <div className="page">
        <PageHeader title="預約成功" back={{ to: '/student/bookings', label: '返回預約管理' }} />
        <Card>
          <div className="success">
            <div className="success-mark" aria-hidden>
              ✓
            </div>
            <div>
              <div className="hero-title">{result.coursename}</div>
              <dl className="meta">
                <dt>預約編號</dt>
                <dd>{result.bookingid}</dd>
                <dt>日期</dt>
                <dd>{fmtMonthDay(result.classdate)}</dd>
                <dt>時間</dt>
                <dd>{fmtTimeRange(result.starttime, result.endtime)}</dd>
                <dt>教練</dt>
                <dd>{result.coachname}</dd>
                <dt>教室</dt>
                <dd>{result.classroom}</dd>
              </dl>
            </div>
          </div>
          <div className="actions">
            <button type="button" className="btn" onClick={reset}>
              再預約一堂
            </button>
            <Link to="/student/bookings" className="btn btn-primary">
              查看預約紀錄
            </Link>
          </div>
        </Card>
      </div>
    );
  }

  return (
    <div className="page">
      <PageHeader title="新增預約" back={{ to: '/student/bookings', label: '返回預約管理' }} />

      <Card title="1. 選擇課程" subtitle="GET /members/courses">
        <AsyncView state={courses} minHeight={90}>
          {(list) =>
            list.length ? (
              <div className="choice-grid">
                {list.map((c) => (
                  <button
                    key={c.membercourseid}
                    type="button"
                    className="choice"
                    aria-pressed={courseId === c.membercourseid}
                    disabled={c.remainingsessions <= 0}
                    onClick={() => setCourseId(c.membercourseid)}
                  >
                    <b>{c.coursename}</b>
                    <span className="muted small">
                      {c.coachname}・剩 {c.remainingsessions} 堂
                    </span>
                  </button>
                ))}
              </div>
            ) : (
              <p className="muted">沒有可預約的課程</p>
            )
          }
        </AsyncView>
      </Card>

      {courseId && (
        <Card title="2. 選擇日期" subtitle="GET /members/courses/{id}/available-dates">
          <AsyncView state={dates} minHeight={320}>
            {(list) =>
              list.length ? (
                <div className="cal-wrap">
                  <MonthCalendar available={list} value={date} onChange={setDate} />
                  <div className="cal-side">
                    {date ? (
                      <>
                        <p className="muted small">已選擇</p>
                        <p className="cal-picked">{fmtMonthDay(date)}</p>
                        <p className="muted small">往下選擇時段</p>
                      </>
                    ) : (
                      <p className="muted small">點選日曆上標示的日期</p>
                    )}
                  </div>
                </div>
              ) : (
                <p className="muted">這門課目前沒有可預約的日期</p>
              )
            }
          </AsyncView>
        </Card>
      )}

      {courseId && date && (
        <Card title="3. 選擇時段" subtitle="GET /members/courses/{id}/schedules?date=，只有「可預約」能選">
          <AsyncView state={slots} minHeight={120}>
            {(list) => (
              <div className="slot-grid">
                {list.map((s) => (
                  <button
                    key={s.scheduleid}
                    type="button"
                    className={`slot st-${s.status}`}
                    aria-pressed={slot?.scheduleid === s.scheduleid}
                    disabled={s.status !== 'available'}
                    onClick={() => setSlot(s)}
                  >
                    <b>{fmtTime(s.starttime)}</b>
                    <span>{{ available: '可預約', booked: '已被預約', closed: '不開放', private: '私人安排' }[s.status]}</span>
                  </button>
                ))}
              </div>
            )}
          </AsyncView>
        </Card>
      )}

      {slot && course && date && (
        <Card title="4. 確認預約" subtitle="POST /booking">
          <dl className="meta">
            <dt>課程</dt>
            <dd>
              {course.coursename}（{course.coachname}）
            </dd>
            <dt>時間</dt>
            <dd>
              {fmtMonthDay(date)} {fmtTimeRange(slot.starttime, slot.endtime)}
            </dd>
          </dl>
          <label className="field">
            <span>備註（選填）</span>
            <textarea value={note} onChange={(e) => setNote(e.target.value)} rows={2} placeholder="例如：想加強下肢" />
          </label>
          {error && <p className="form-error">{error}</p>}
          <div className="actions">
            <button type="button" className="btn btn-primary" disabled={submitting} onClick={() => void submit()}>
              {submitting ? '送出中…' : '確認預約'}
            </button>
          </div>
        </Card>
      )}
    </div>
  );
}
