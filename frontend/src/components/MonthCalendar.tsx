import { useEffect, useMemo, useState } from 'react';
import { parseDate, toISODate, todayISO } from '../utils/format';

const WEEKDAYS = ['日', '一', '二', '三', '四', '五', '六'];

interface MonthCalendarProps {
  /** 可以選的日期（GET /members/courses/{id}/available-dates 的回傳），格式 yyyy-MM-dd */
  available: string[];
  value?: string;
  onChange: (date: string) => void;
}

const monthStart = (d: Date) => new Date(d.getFullYear(), d.getMonth(), 1);
const monthKey = (d: Date) => d.getFullYear() * 12 + d.getMonth();

/**
 * 月曆選日期：只有 available 裡的日期可以點，其他日期顯示為灰色。
 * 左右箭頭切換月份，範圍限制在「今天所在月份」到「最後一個可預約日的月份」。
 */
export function MonthCalendar({ available, value, onChange }: MonthCalendarProps) {
  const sorted = useMemo(() => [...available].sort(), [available]);
  const availableSet = useMemo(() => new Set(sorted), [sorted]);
  const today = todayISO();

  const firstAvailable = sorted[0];
  const minMonth = monthStart(parseDate(firstAvailable && firstAvailable < today ? firstAvailable : today));
  const maxMonth = monthStart(parseDate(sorted[sorted.length - 1] ?? today));

  const [view, setView] = useState(() => monthStart(parseDate(value ?? firstAvailable ?? today)));

  // 換課程時，跳到新的第一個可預約日所在的月份
  useEffect(() => {
    setView(monthStart(parseDate(value ?? firstAvailable ?? today)));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [firstAvailable]);

  const year = view.getFullYear();
  const month = view.getMonth();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const leading = new Date(year, month, 1).getDay();
  const cells: (string | null)[] = [
    ...Array<null>(leading).fill(null),
    ...Array.from({ length: daysInMonth }, (_, i) => toISODate(new Date(year, month, i + 1))),
  ];
  while (cells.length % 7) cells.push(null);

  const countThisMonth = sorted.filter((d) => {
    const p = parseDate(d);
    return p.getFullYear() === year && p.getMonth() === month;
  }).length;

  const canPrev = monthKey(view) > monthKey(minMonth);
  const canNext = monthKey(view) < monthKey(maxMonth);
  const shift = (n: number) => setView(new Date(year, month + n, 1));

  return (
    <div className="cal">
      <div className="cal-head">
        <button type="button" className="cal-nav" onClick={() => shift(-1)} disabled={!canPrev} aria-label="上個月">
          ‹
        </button>
        <div className="cal-title">
          {year} 年 {month + 1} 月
          <span className="muted small">本月 {countThisMonth} 天可預約</span>
        </div>
        <button type="button" className="cal-nav" onClick={() => shift(1)} disabled={!canNext} aria-label="下個月">
          ›
        </button>
      </div>

      <div className="cal-grid" role="grid" aria-label={`${year} 年 ${month + 1} 月`}>
        {WEEKDAYS.map((w, i) => (
          <div key={w} className={`cal-weekday ${i === 0 || i === 6 ? 'is-weekend' : ''}`} role="columnheader">
            {w}
          </div>
        ))}
        {cells.map((iso, i) =>
          iso ? (
            <button
              key={iso}
              type="button"
              role="gridcell"
              className={[
                'cal-day',
                availableSet.has(iso) ? 'is-available' : '',
                iso === value ? 'is-selected' : '',
                iso === today ? 'is-today' : '',
              ].join(' ')}
              disabled={!availableSet.has(iso)}
              aria-pressed={iso === value}
              aria-label={`${month + 1} 月 ${parseDate(iso).getDate()} 日${availableSet.has(iso) ? '，可預約' : '，不可預約'}`}
              onClick={() => onChange(iso)}
            >
              <span>{parseDate(iso).getDate()}</span>
              {iso === today && <small>今天</small>}
            </button>
          ) : (
            <div key={`blank-${i}`} className="cal-blank" />
          ),
        )}
      </div>

      <div className="legend cal-legend">
        <span>
          <i className="swatch cal-swatch-available" />
          可預約
        </span>
        <span>
          <i className="swatch cal-swatch-selected" />
          已選擇
        </span>
        <span>
          <i className="swatch cal-swatch-off" />
          不開放
        </span>
      </div>
    </div>
  );
}
