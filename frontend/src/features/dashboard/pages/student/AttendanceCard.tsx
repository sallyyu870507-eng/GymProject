import { useEffect, useState } from 'react';
import { Link } from 'react-router';
import { request } from '../../../../api.js';
import { Card } from '../../components/ui';

type WeeklyAttendance = {
  week: string;
  checkins: number;
};

export default function AttendanceCard() {
  const [weeks, setWeeks] = useState<WeeklyAttendance[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    const controller = new AbortController();

    setLoading(true);
    setError('');

    request('/api/member/attendance?weeks=12', {
      signal: controller.signal,
    })
      .then((data) => {
        if (controller.signal.aborted) return;

        if (
          !Array.isArray(data) ||
          data.some((item) =>
            !item ||
            typeof item.week !== 'string' ||
            !Number.isInteger(item.checkins) ||
            item.checkins < 0,
          )
        ) {
          throw new Error('出席紀錄回傳格式不正確');
        }

        setWeeks([...data].sort((a, b) => a.week.localeCompare(b.week)));
      })
      .catch((failure: unknown) => {
        if (controller.signal.aborted) return;
        setWeeks([]);
        setError(
          failure instanceof Error
            ? failure.message
            : '出席紀錄讀取失敗',
        );
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false);
      });

    return () => controller.abort();
  }, [attempt]);

  const total = weeks.reduce((sum, item) => sum + item.checkins, 0);
  const activeWeeks = weeks.filter((item) => item.checkins > 0).length;
  const average = weeks.length ? (total / weeks.length).toFixed(1) : '0.0';
  const maximum = Math.max(1, ...weeks.map((item) => item.checkins));

  return (
    <Card
      title="出席紀錄"
      footer={
        <>
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
        </>
      }
    >
      {loading ? (
        <p role="status">出席紀錄載入中…</p>
      ) : error ? (
        <p role="alert">{error}</p>
      ) : !weeks.length ? (
        <p className="muted">目前尚無出席紀錄。</p>
      ) : (
        <>
          <div className="mini-stats">
            <div>
              <b>{total}</b>
              <span>近 {weeks.length} 週出席次數</span>
            </div>
            <div>
              <b>{activeWeeks}</b>
              <span>有出席的週數</span>
            </div>
            <div>
              <b>{average}</b>
              <span>平均每週出席次數</span>
            </div>
          </div>

          <figure style={{ margin: '24px 0 0' }}>
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: `repeat(${weeks.length}, minmax(0, 1fr))`,
                gap: 6,
                alignItems: 'end',
                height: 160,
                borderBottom: '1px solid var(--line)',
              }}
            >
              {weeks.map((item) => (
                <div
                  key={item.week}
                  title={`${item.week} 當週：出席 ${item.checkins} 次`}
                  aria-label={`${item.week} 當週出席 ${item.checkins} 次`}
                  style={{ textAlign: 'center', minWidth: 0 }}
                >
                  <span style={{ fontSize: 12, color: 'var(--muted)' }}>
                    {item.checkins}
                  </span>
                  <div
                    aria-hidden="true"
                    style={{
                      height: (item.checkins / maximum) * 120,
                      background: 'var(--c1)',
                      borderRadius: '4px 4px 0 0',
                    }}
                  />
                </div>
              ))}
            </div>

            <figcaption
              className="muted small"
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                flexWrap: 'wrap',
                gap: 8,
                marginTop: 8,
              }}
            >
              <span>{weeks[0].week}</span>
              <span>每柱代表一週，單位：次</span>
              <span>{weeks[weeks.length - 1].week}</span>
            </figcaption>
          </figure>
        </>
      )}
    </Card>
  );
}