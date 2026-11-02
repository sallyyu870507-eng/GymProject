const WEEKDAYS = '日一二三四五六';
const pad = (n: number) => String(n).padStart(2, '0');

/** Date → "2026-10-18"（本地時間） */
export function toISODate(d: Date): string {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

export const todayISO = () => toISODate(new Date());

export function addDaysISO(days: number, from = new Date()): string {
  const d = new Date(from);
  d.setDate(d.getDate() + days);
  return toISODate(d);
}

/** "2026-10-18" → 本地時間的 Date（避免 new Date(str) 被當成 UTC） */
export function parseDate(s: string): Date {
  const [y, m, d] = s.slice(0, 10).split('-').map(Number);
  return new Date(y, m - 1, d);
}

export function toDateTime(date: string, time: string): Date {
  const d = parseDate(date);
  const [h, mi] = time.split(':').map(Number);
  d.setHours(h, mi || 0, 0, 0);
  return d;
}

/** 10/18（六） */
export function fmtMonthDay(s: string): string {
  const d = parseDate(s);
  return `${d.getMonth() + 1}/${d.getDate()}（${WEEKDAYS[d.getDay()]}）`;
}

/** 2026/10/18 */
export function fmtDate(s: string): string {
  const d = parseDate(s);
  return `${d.getFullYear()}/${d.getMonth() + 1}/${d.getDate()}`;
}

/** "09:00:00" → "09:00" */
export const fmtTime = (t: string) => t.slice(0, 5);
export const fmtTimeRange = (start: string, end: string) => `${fmtTime(start)}–${fmtTime(end)}`;

export const fmtNumber = (n: number) => n.toLocaleString('zh-TW');
export const fmtPercent = (ratio: number) => `${Math.round(ratio * 100)}%`;

/** +0.4 / −1.2 / ±0 */
export function fmtSigned(v: number, digits = 1): string {
  const sign = v > 0 ? '+' : v < 0 ? '−' : '±';
  return sign + Math.abs(v).toFixed(digits);
}

/** 今天到某一天差幾天（負數代表已經過了） */
export function daysUntil(date: string): number {
  return Math.round((parseDate(date).getTime() - parseDate(todayISO()).getTime()) / 86_400_000);
}

/** 毫秒 → 「2 天 3 小時」/「45 分鐘」 */
export function fmtDuration(ms: number): string {
  const mins = Math.max(0, Math.round(ms / 60_000));
  const d = Math.floor(mins / 1440);
  const h = Math.floor((mins % 1440) / 60);
  const m = mins % 60;
  if (d) return `${d} 天 ${h} 小時`;
  if (h) return `${h} 小時 ${m} 分`;
  return `${m} 分鐘`;
}
