import { useEffect, useState } from 'react';
import { bookingApi, memberApi } from '../api/member';
import type { BookingResult, ScheduleSlot } from '../api/types';
import { useApi } from '../hooks/useApi';
import { fmtMonthDay, fmtTime, fmtTimeRange } from '../utils/format';
import { MonthCalendar } from './MonthCalendar';
import { AsyncView } from './ui';

interface Props {
  booking: BookingResult;
  onDone: (message: string) => void;
  onClose: () => void;
}

/**
 * 會員改期：PUT /booking/{id}/reschedule { newScheduleid }
 * 後端規定只能換「同課程、同教練」的時段，所以日期和時段沿用預約流程的 4.2 / 4.3 API。
 * /booking/my 沒有回傳 membercourseid，這裡用課程名稱＋教練名稱對回 /members/courses。
 */
export function RescheduleDialog({ booking, onDone, onClose }: Props) {
  const courses = useApi((s) => memberApi.courses(s), []);
  const course = courses.data?.find((c) => c.coursename === booking.coursename && c.coachname === booking.coachname);
  const courseId = course?.membercourseid;

  const [date, setDate] = useState<string>();
  const [slot, setSlot] = useState<ScheduleSlot>();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string>();

  const dates = useApi(
    (s) => (courseId ? memberApi.availableDates(courseId, s) : Promise.resolve<string[]>([])),
    [courseId],
  );
  const slots = useApi(
    (s) => (courseId && date ? memberApi.schedules(courseId, date, s) : Promise.resolve<ScheduleSlot[]>([])),
    [courseId, date],
  );
  useEffect(() => setSlot(undefined), [date]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && !busy && onClose();
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [busy, onClose]);

  const submit = async () => {
    if (!slot) return;
    setBusy(true);
    setError(undefined);
    try {
      const msg = await bookingApi.reschedule(booking.bookingid, slot.scheduleid);
      onDone(typeof msg === 'string' && msg ? msg : '修改預約成功');
    } catch (err) {
      setError((err as Error).message);
      slots.reload();
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="dialog-backdrop" onMouseDown={(e) => e.target === e.currentTarget && !busy && onClose()}>
      <div className="dialog dialog-wide card" role="dialog" aria-modal="true" aria-label="修改預約">
        <header className="card-head">
          <div>
            <h3>修改預約</h3>
            <p className="muted small">
              原本：{fmtMonthDay(booking.classdate)} {fmtTimeRange(booking.starttime, booking.endtime)}・{booking.coursename}（
              {booking.coachname}）
            </p>
          </div>
          <button type="button" className="btn btn-ghost btn-small" onClick={onClose} disabled={busy} aria-label="關閉">
            ✕
          </button>
        </header>

        <AsyncView state={courses} minHeight={120}>
          {() =>
            !courseId ? (
              <p className="form-error">找不到這堂課對應的已購課程（可能剩餘堂數為 0），無法改期。</p>
            ) : (
              <>
                <AsyncView state={dates} minHeight={300}>
                  {(list) =>
                    list.length ? (
                      <div className="cal-wrap">
                        <MonthCalendar available={list} value={date} onChange={setDate} />
                        <div className="cal-side">
                          {date ? (
                            <>
                              <p className="muted small">新日期</p>
                              <p className="cal-picked">{fmtMonthDay(date)}</p>
                            </>
                          ) : (
                            <p className="muted small">選一個新日期（只能選明天以後）</p>
                          )}
                        </div>
                      </div>
                    ) : (
                      <p className="muted">這門課目前沒有其他可預約的日期</p>
                    )
                  }
                </AsyncView>

                {date && (
                  <AsyncView state={slots} minHeight={80}>
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
                            <span>
                              {{ available: '可預約', booked: '已被預約', closed: '不開放', private: '私人安排' }[s.status]}
                            </span>
                          </button>
                        ))}
                      </div>
                    )}
                  </AsyncView>
                )}
              </>
            )
          }
        </AsyncView>

        {error && <p className="form-error">{error}</p>}
        <div className="actions">
          <button type="button" className="btn" onClick={onClose} disabled={busy}>
            取消
          </button>
          <button type="button" className="btn btn-primary" disabled={!slot || busy} onClick={() => void submit()}>
            {busy ? '送出中…' : slot && date ? `改到 ${fmtMonthDay(date)} ${fmtTime(slot.starttime)}` : '確認修改'}
          </button>
        </div>
      </div>
    </div>
  );
}
