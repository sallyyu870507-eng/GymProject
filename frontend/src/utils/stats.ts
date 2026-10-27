import type { BookingResult, InBodyRecord } from '../api/types';
import { toDateTime } from './format';

/** 還沒結束、狀態是 booked 的課，依時間排序 */
export function upcomingBookings(list: BookingResult[], now = new Date()): BookingResult[] {
  return list
    .filter((b) => b.bookingstatus === 'booked' && toDateTime(b.classdate, b.endtime) > now)
    .sort(
      (a, b) =>
        toDateTime(a.classdate, a.starttime).getTime() - toDateTime(b.classdate, b.starttime).getTime(),
    );
}

export function countBy<T>(list: T[], key: (item: T) => string): Record<string, number> {
  const out: Record<string, number> = {};
  for (const item of list) {
    const k = key(item);
    out[k] = (out[k] ?? 0) + 1;
  }
  return out;
}

/** inbodyrecords 的三個數值欄位，加上前端換算的體脂肪重 */
export type InBodyMetric = 'weight' | 'musclemass' | 'bodyfatpct' | 'fatmass';

export const INBODY_METRICS: Record<
  InBodyMetric,
  { label: string; unit: string; digits: number; goodWhen: 'up' | 'down' }
> = {
  weight: { label: '體重', unit: 'kg', digits: 1, goodWhen: 'down' },
  musclemass: { label: '肌肉量', unit: 'kg', digits: 1, goodWhen: 'up' },
  bodyfatpct: { label: '體脂率', unit: '%', digits: 1, goodWhen: 'down' },
  fatmass: { label: '體脂肪重', unit: 'kg', digits: 1, goodWhen: 'down' },
};

/** 取某個指標的值；fatmass = 體重 × 體脂率（資料表沒有，前端換算） */
export function metricValue(r: InBodyRecord, m: InBodyMetric): number {
  if (m === 'fatmass') return Math.round(((r.weight * r.bodyfatpct) / 100) * 10) / 10;
  return Number(r[m]);
}

/** 依日期排序後，回傳最新、上一次、第一次 */
export function summarizeInBody(rows: InBodyRecord[]) {
  const sorted = [...rows].sort((a, b) => a.recorddate.localeCompare(b.recorddate));
  const latest = sorted[sorted.length - 1];
  const previous = sorted[sorted.length - 2] ?? latest;
  const first = sorted[0];
  const delta = (m: InBodyMetric, base: InBodyRecord | undefined) =>
    latest && base ? Math.round((metricValue(latest, m) - metricValue(base, m)) * 10) / 10 : 0;
  return {
    sorted,
    latest,
    previous,
    first,
    deltaPrev: (m: InBodyMetric) => delta(m, previous),
    deltaFirst: (m: InBodyMetric) => delta(m, first),
  };
}
