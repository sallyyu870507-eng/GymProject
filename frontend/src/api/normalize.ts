import type { SlotStatus } from './types';

/**
 * classschedule.status 在資料表的預設值是 'open'，規格書寫 'available'。
 * 後端不管回哪一種，前端都統一成 'available'，畫面只要處理一種。
 */
export function normalizeSlotStatus(status: string): SlotStatus {
  const s = status?.trim().toLowerCase();
  if (s === 'open' || s === 'available') return 'available';
  if (s === 'booked' || s === 'closed' || s === 'private') return s;
  return 'closed';
}

export function withNormalizedStatus<T extends { status: string }>(rows: T[]): (T & { status: SlotStatus })[] {
  return rows.map((r) => ({ ...r, status: normalizeSlotStatus(r.status) }));
}

/**
 * 測試資料的 bookingstatus 是大寫（BOOKED / CANCELLED），規格書範例是小寫。
 * 前端統一轉成小寫，畫面判斷時只要處理一種。
 */
export function normalizeBookingStatus(status: string): string {
  const s = status?.trim().toLowerCase() ?? '';
  if (s === 'canceled' || s === 'cancel') return 'cancelled';
  return s;
}

export function withNormalizedBooking<T extends { bookingstatus: string }>(rows: T[]): T[] {
  return rows.map((r) => ({ ...r, bookingstatus: normalizeBookingStatus(r.bookingstatus) }));
}
