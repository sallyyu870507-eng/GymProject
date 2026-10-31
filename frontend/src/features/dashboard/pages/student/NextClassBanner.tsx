import { useEffect, useState } from 'react';
import { Link } from 'react-router';
import { request } from '../../../../api.js';

type Booking = {
  bookingid: number;
  coursename: string;
  coachname: string;
  classdate: string;
  starttime: string;
  endtime: string;
  classroom: string | null;
  bookingstatus: string;
};

function startTimestamp(booking: Booking) {
  return Date.parse(
    `${booking.classdate}T${booking.starttime}+08:00`,
  );
}

export default function NextClassBanner({
  fromDate,
}: {
  fromDate: string;
}) {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [attempt, setAttempt] = useState(0);
  const [now, setNow] = useState(Date.now);

  useEffect(() => {
    const timer = setInterval(() => setNow(Date.now()), 30000);
    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    const controller = new AbortController();

    setLoading(true);
    setError('');

    request('/api/member/bookings', {
      signal: controller.signal,
    })
      .then((data) => {
        if (controller.signal.aborted) return;
        if (!Array.isArray(data)) {
          throw new Error('預約紀錄回傳格式不正確');
        }
        setBookings(data);
        setNow(Date.now());
      })
      .catch((failure: unknown) => {
        if (controller.signal.aborted) return;
        setBookings([]);
        setError(
          failure instanceof Error
            ? failure.message
            : '預約紀錄讀取失敗',
        );
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false);
      });

    return () => controller.abort();
  }, [attempt]);

  const selectedStart = Date.parse(`${fromDate}T00:00:00+08:00`);
  const cutoff = Number.isFinite(selectedStart)
    ? Math.max(now, selectedStart)
    : now;

  const next = bookings
    .filter((booking) => {
      const start = startTimestamp(booking);

      return (
        booking.bookingstatus?.trim().toLowerCase() === 'booked' &&
        Number.isFinite(start) &&
        start >= cutoff
      );
    })
    .sort((a, b) => startTimestamp(a) - startTimestamp(b))[0];

  return (
    <section className="card next-bar">
      <h2>下一堂課</h2>

      <div className="next-info">
        {loading ? (
          <p role="status">預約紀錄載入中…</p>
        ) : error ? (
          <p role="alert">{error}</p>
        ) : next ? (
          <>
            <div className="next-when">
              {next.classdate}{next.starttime.slice(0, 5)}
              {' – '}
              {next.endtime?.slice(0, 5) || '未提供結束時間'}
            </div>

            <div>
              {next.coursename || '未提供課程名稱'}
              {next.classroom ? `・${next.classroom}` : ''}
            </div>

            <div>教練：{next.coachname || '未提供'}</div>
          </>
        ) : (
          <p className="muted">
            從 {fromDate} 起，目前沒有尚未開始的預約。
          </p>
        )}
      </div>

      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
        <button
          type="button"
          className="btn"
          disabled={loading}
          onClick={() => setAttempt((value) => value + 1)}
        >
          重新讀取
        </button>

        <Link to="/my-bookings" className="btn">
          查看預約
        </Link>
      </div>
    </section>
  );
}