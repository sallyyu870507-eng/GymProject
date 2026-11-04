import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router';
import { request } from '../../../../api.js';
import { Card } from '../../components/ui';

type WeeklyAttendance = {
  week: string;
  checkins: number;
};

function parseWeekDate(value: string) {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (!match) return null;
  const date = new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
  return Number.isNaN(date.getTime()) ? null : date;
}

function formatDate(date: Date) {
  return `${date.getFullYear()}/${String(date.getMonth() + 1).padStart(2, '0')}/${String(date.getDate()).padStart(2, '0')}`;
}

function weekRange(value: string) {
  const start = parseWeekDate(value);
  if (!start) return `${value}（日期格式無法辨識）`;
  const end = new Date(start.getFullYear(), start.getMonth(), start.getDate() + 6);
  return `${formatDate(start)}～${formatDate(end)}`;
}

function monthDay(value: string) {
  const date = parseWeekDate(value);
  return date ? `${String(date.getMonth() + 1).padStart(2, '0')}/${String(date.getDate()).padStart(2, '0')}` : value;
}

function integerStep(maximum: number) {
  const raw = Math.max(1, maximum / 4);
  const magnitude = 10 ** Math.floor(Math.log10(raw));
  const fraction = raw / magnitude;
  const factor = fraction <= 1 ? 1 : fraction <= 2 ? 2 : fraction <= 5 ? 5 : 10;
  return Math.max(1, Math.ceil(factor * magnitude));
}

export default function AttendanceCard() {
  const [weeks, setWeeks] = useState<WeeklyAttendance[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [attempt, setAttempt] = useState(0);
  const [selectedWeek, setSelectedWeek] = useState<string | null>(null);
  const chartRef = useRef<HTMLElement>(null);
  const [chartWidth, setChartWidth] = useState(720);

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

  useEffect(() => {
    const element = chartRef.current;
    if (!element || typeof ResizeObserver === 'undefined') return;
    const observer = new ResizeObserver(([entry]) => setChartWidth(entry.contentRect.width));
    observer.observe(element);
    return () => observer.disconnect();
  }, []);

  const total = weeks.reduce((sum, item) => sum + item.checkins, 0);
  const activeWeeks = weeks.filter((item) => item.checkins > 0).length;
  const average = weeks.length ? (total / weeks.length).toFixed(1) : '0.0';
  const maximum = Math.max(1, ...weeks.map((item) => item.checkins));
  const step = integerStep(maximum);
  const axisMax = Math.max(step, Math.ceil(maximum / step) * step);
  const ticks = Array.from({ length: Math.floor(axisMax / step) + 1 }, (_, index) => index * step);
  const selected = weeks.find((item) => item.week === selectedWeek);
  const labelLimit = Math.min(weeks.length, Math.max(2, Math.floor((chartWidth - 40) / 38)));
  const labelIndexes = new Set<number>();
  if (weeks.length <= labelLimit) {
    weeks.forEach((_, index) => labelIndexes.add(index));
  } else {
    for (let i = 0; i < labelLimit; i += 1) {
      labelIndexes.add(Math.round(i * (weeks.length - 1) / (labelLimit - 1)));
    }
  }
  const graphTop = 20;
  const graphBottom = 136;
  const graphHeight = graphBottom - graphTop;
  const yForValue = (value: number) => graphTop + (1 - value / axisMax) * graphHeight;

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
          <div className="member-dashboard-stats member-attendance-stats">
            <div className="member-dashboard-stat"><span className="member-dashboard-stat-label">近 {weeks.length} 週出席次數</span><strong>{total}<small>次</small></strong></div>
            <div className="member-dashboard-stat"><span className="member-dashboard-stat-label">有出席的週數</span><strong>{activeWeeks}<small>週</small></strong></div>
            <div className="member-dashboard-stat"><span className="member-dashboard-stat-label">平均每週出席次數</span><strong>{average}<small>次</small></strong></div>
          </div>

          <figure className="member-attendance-figure" ref={chartRef}>
            <figcaption className="member-attendance-caption">每柱代表一週</figcaption>
            <div className="member-attendance-chart">
              <div className="member-attendance-y-axis" aria-hidden="true">
                <span className="member-attendance-y-unit">次</span>
                {ticks.map((tick) => <span key={tick} style={{ top: `${yForValue(tick)}px` }}>{tick}</span>)}
              </div>
              <div className="member-attendance-plot">
                {ticks.map((tick) => (
                  <div key={tick} className="member-attendance-grid-line" style={{ top: `${yForValue(tick)}px` }} />
                ))}
                <div className="member-attendance-columns" style={{ gridTemplateColumns: `repeat(${weeks.length}, minmax(0, 1fr))` }}>
                  {weeks.map((item) => (
                    <button
                      key={item.week}
                      type="button"
                      className={`member-attendance-column${selectedWeek === item.week ? ' is-selected' : ''}`}
                      title={`${weekRange(item.week)}：出席 ${item.checkins} 次`}
                      aria-label={`${weekRange(item.week)}，出席 ${item.checkins} 次`}
                      aria-pressed={selectedWeek === item.week}
                      onClick={() => setSelectedWeek((current) => current === item.week ? null : item.week)}
                    >
                      <span className={`member-attendance-count${item.checkins === 0 ? ' is-zero' : ''}`} style={{ top: `${yForValue(item.checkins) - 18}px` }}>{item.checkins || ''}</span>
                      <span
                        className={`member-attendance-bar${item.checkins === 0 ? ' is-zero' : ''}`}
                        style={{ height: `${(item.checkins / axisMax) * graphHeight}px` }}
                        aria-hidden="true"
                      />
                    </button>
                  ))}
                </div>
              </div>
            </div>
            <div className="member-attendance-x-title">週起始日</div>
            <div className="member-attendance-x-axis" style={{ gridTemplateColumns: `repeat(${weeks.length}, minmax(0, 1fr))` }}>
              {weeks.map((item, index) => <span key={item.week}>{labelIndexes.has(index) ? monthDay(item.week) : ''}</span>)}
            </div>
            {selected && <p className="member-attendance-detail" role="status">{weekRange(selected.week)}：出席 {selected.checkins} 次</p>}
          </figure>
        </>
      )}
    </Card>
  );
}
