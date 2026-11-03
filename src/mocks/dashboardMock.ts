/**
 * 【截圖用假資料】後端沒開也能看到完整畫面。
 *
 * - SHOW_MOCK = false：呼叫後端 API（預設，需要先啟動 Spring Boot 並登入）
 * - SHOW_MOCK = true ：顯示這個檔案裡的假資料，不呼叫後端
 *
 * 欄位格式和後端 API 一樣（型別在 src/api/dashboard.ts）。
 * 內容參考測試資料 SQLQuery2.sql（member001 陳怡君、教練 Alex～Emma、5 種課程）。
 */
import type { BookingStats, CoachProfile, InBodyRecord, MemberCourse, MemberProfile, NextClass, ScheduleRow, WeeklyAttendance } from '../api/dashboard';
import { addDaysISO, parseDate, toISODate, todayISO } from '../utils/format';

export const SHOW_MOCK = false;

/* ───────────── 學員端 ───────────── */

/** GET /api/member/profile */
export const mockProfile: MemberProfile = {
  memberid: 1,
  memberno: 'M001',
  name: '陳怡君',
  gender: '女',
  phone: '0900000001',
  email: 'member001@example.com',
  birthday: '1985-05-18',
  avatarurl: null,
  status: 'active',
};

/** GET /api/member/next-class */
export const mockNextClass: NextClass = {
  bookingid: 1,
  scheduleid: 1,
  classroom: 'A 教室',
  classdate: addDaysISO(1),
  starttime: '10:00',
  endtime: '11:00',
  coursename: '肌力基礎',
  coursetype: '一對一',
  coachname: 'Alex',
};

/** 本週的週一 */
function mondayOf(iso: string): Date {
  const d = parseDate(iso);
  d.setDate(d.getDate() - ((d.getDay() + 6) % 7));
  return d;
}

/** GET /api/member/attendance?weeks=12（舊 → 新，沒來的週為 0） */
export const mockAttendance: WeeklyAttendance[] = (() => {
  const counts = [0, 1, 2, 1, 0, 2, 3, 2, 1, 2, 3, 1];
  const mon = mondayOf(todayISO());
  return counts.map((checkins, i) => {
    const d = new Date(mon);
    d.setDate(d.getDate() - (counts.length - 1 - i) * 7);
    return { week: toISODate(d), checkins };
  });
})();

/** GET /api/member/booking-stats */
export const mockBookingStats: BookingStats = { completed: 16, cancelled: 2, upcoming: 1 };

/** GET /api/member/inbody（舊 → 新） */
export const mockInBody: InBodyRecord[] = [
  { inbodyid: 1, recorddate: addDaysISO(-56), weight: 62.4, bodyfatpct: 29.8, musclemass: 22.1 },
  { inbodyid: 2, recorddate: addDaysISO(-42), weight: 61.9, bodyfatpct: 29.1, musclemass: 22.3 },
  { inbodyid: 3, recorddate: addDaysISO(-28), weight: 61.2, bodyfatpct: 28.2, musclemass: 22.6 },
  { inbodyid: 4, recorddate: addDaysISO(-14), weight: 60.8, bodyfatpct: 27.6, musclemass: 22.9 },
  { inbodyid: 5, recorddate: addDaysISO(-3), weight: 60.3, bodyfatpct: 26.9, musclemass: 23.2 },
];

/** GET /api/member/courses */
export const mockCourses: MemberCourse[] = [
  { membercourseid: 2, coursename: '核心穩定', coachname: 'Brian', totalsessions: 8, remainingsessions: 2, purchasedate: addDaysISO(-60), status: 'active' },
  { membercourseid: 1, coursename: '肌力基礎', coachname: 'Alex', totalsessions: 12, remainingsessions: 7, purchasedate: addDaysISO(-90), status: 'active' },
];

/* ───────────── 教練端 ───────────── */

export type GymScheduleRow = ScheduleRow;

/** GET /api/coach/profile */
export const mockCoachProfile: CoachProfile = {
  coachid: 1,
  coachno: 'C001',
  name: 'Alex',
  gender: '男',
  phone: '0901000001',
  email: 'coach001@example.com',
  specialty: '肌力基礎、核心穩定、有氧體能',
  status: 'active',
};
const mockCoach = { coachid: mockCoachProfile.coachid, name: mockCoachProfile.name };

/** GET /api/coach/schedules/mine?date=… */
export function mockCoachSchedule(date: string): GymScheduleRow[] {
  const rows: Array<[string, string, string, string | null, string | null]> = [
    ['08:00', '09:00', 'booked', '林志豪', '肌力基礎'],
    ['10:00', '11:00', 'booked', '陳怡君', '肌力基礎'],
    ['13:00', '14:00', 'booked', '黃雅婷', '核心穩定'],
    ['15:00', '16:00', 'booked', '王俊傑', '有氧體能'],
    ['18:00', '19:00', 'available', null, null],
    ['19:00', '20:00', 'available', null, null],
  ];
  return rows.map(([starttime, endtime, status, membername, coursename], i) => ({
    scheduleid: 100 + i,
    coachid: mockCoach.coachid,
    coachname: mockCoach.name,
    classdate: date,
    starttime,
    endtime,
    status,
    membername,
    coursename,
  }));
}
