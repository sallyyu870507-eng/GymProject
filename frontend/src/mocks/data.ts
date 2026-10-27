/**
 * 示範資料：欄位與後端 API 規格書一致，日期會以「今天」為基準自動產生。
 * 接上真後端後這個檔案就用不到了（ready=false 的 API 除外）。
 */
import { ApiError } from '../api/client';
import type {
  BookingRequest,
  BookingResult,
  BookingStatus,
  CoachDashboard,
  CoachInfo,
  CoachScheduleItem,
  CourseCatalogItem,
  DayScheduleItem,
  InBodyRecord,
  MemberCourse,
  MemberProfile,
  ScheduleSlot,
  SlotStatus,
  WeeklyAttendance,
} from '../api/types';
import { addDaysISO, parseDate, toISODate, todayISO } from '../utils/format';

const hh = (h: number) => `${String(h).padStart(2, '0')}:00:00`;

/** 固定種子的亂數，同一天每次重整看到的資料一樣 */
function seeded(seed: number) {
  let s = seed % 2147483647 || 1;
  return () => (s = (s * 16807) % 2147483647) / 2147483647;
}
function hash(str: string) {
  let h = 7;
  for (const ch of str) h = (h * 31 + ch.charCodeAt(0)) | 0;
  return Math.abs(h) + 1;
}

/* ───────────── 會員 ───────────── */

export const mockMemberCourses: MemberCourse[] = [
  { membercourseid: 1, courseid: 1, coursename: '一對一重訓', coachid: 1, coachname: '王教練', remainingsessions: 8, totalsessions: 24, purchasedate: addDaysISO(-160) },
  { membercourseid: 2, courseid: 4, coursename: '體態雕塑', coachid: 2, coachname: '李教練', remainingsessions: 5, totalsessions: 10, purchasedate: addDaysISO(-60) },
  { membercourseid: 3, courseid: 3, coursename: '伸展放鬆', coachid: 3, coachname: '陳教練', remainingsessions: 2, totalsessions: 8, purchasedate: addDaysISO(-70) },
];

export const mockProfile: MemberProfile = {
  memberid: 1,
  memberno: 'M000001',
  name: '王小明',
  gender: '男',
  phone: '0911000002',
  email: 'member01@example.com',
  birthday: '2000-01-01',
  avatarurl: null,
  status: 'active',
};

const ROOM: Record<string, string> = { 一對一重訓: 'A 館', 體態雕塑: 'B 館 團課教室', 伸展放鬆: 'B 館 瑜珈室' };
const COACH_OF: Record<string, string> = { 一對一重訓: '王教練', 體態雕塑: '李教練', 伸展放鬆: '陳教練' };

const BOOKING_PLAN: [number, number, string, BookingStatus][] = [
  [-35, 19, '一對一重訓', 'completed'], [-31, 10, '伸展放鬆', 'completed'], [-28, 19, '一對一重訓', 'completed'],
  [-24, 18, '體態雕塑', 'completed'], [-21, 19, '一對一重訓', 'cancelled'], [-17, 18, '體態雕塑', 'completed'],
  [-14, 19, '一對一重訓', 'completed'], [-10, 18, '體態雕塑', 'completed'], [-8, 10, '伸展放鬆', 'completed'],
  [-7, 19, '一對一重訓', 'completed'], [-3, 18, '體態雕塑', 'cancelled'], [0, 19, '一對一重訓', 'booked'],
  [2, 10, '伸展放鬆', 'booked'], [4, 18, '體態雕塑', 'booked'], [7, 19, '一對一重訓', 'booked'],
  [11, 18, '體態雕塑', 'booked'], [14, 19, '一對一重訓', 'booked'],
];

export const mockBookings: BookingResult[] = BOOKING_PLAN.map(([day, hour, course, status], i) => ({
  bookingid: 501 + i,
  coursename: course,
  coachname: COACH_OF[course],
  classdate: addDaysISO(day),
  starttime: hh(hour),
  endtime: hh(hour + 1),
  classroom: ROOM[course],
  bookingstatus: status,
}));

export const mockAttendance: WeeklyAttendance[] = (() => {
  const monday = new Date();
  monday.setDate(monday.getDate() - ((monday.getDay() + 6) % 7));
  const values = [2, 3, 3, 1, 2, 4, 3, 3, 2, 4, 3, 2];
  return values.map((checkins, i) => {
    const d = new Date(monday);
    d.setDate(d.getDate() - 7 * (values.length - 1 - i));
    return { week: toISODate(d), checkins };
  });
})();

export const mockInBody: InBodyRecord[] = (() => {
  const weight = [78.4, 77.6, 77.1, 76.5, 76.0, 75.6, 75.1, 74.9, 74.5, 74.1];
  const muscle = [31.2, 31.3, 31.5, 31.7, 31.9, 32.1, 32.3, 32.5, 32.8, 33.0];
  const pct = [26.8, 26.0, 25.3, 24.5, 23.9, 23.3, 22.7, 22.3, 21.9, 21.5];
  return weight.map((w, i) => ({
    inbodyid: i + 1,
    recorddate: addDaysISO(-8 - 28 * (weight.length - 1 - i)),
    weight: w,
    bodyfatpct: pct[i],
    musclemass: muscle[i],
  }));
})();

export const mockCatalog: CourseCatalogItem[] = [
  { courseid: 1, coursename: '一對一重訓', coursetype: '私人教練', description: '教練一對一指導重量訓練', durationmin: 60, price: 28800, status: 'active', coaches: ['王教練', '林教練', '張教練'] },
  { courseid: 2, coursename: '增肌計畫', coursetype: '私人教練', description: '12 週增肌課表與飲食建議', durationmin: 60, price: 15600, status: 'active', coaches: ['王教練', '張教練'] },
  { courseid: 3, coursename: '伸展放鬆', coursetype: '私人教練', description: '筋膜放鬆與柔軟度訓練', durationmin: 50, price: 7200, status: 'active', coaches: ['陳教練'] },
  { courseid: 4, coursename: '體態雕塑', coursetype: '小團體', description: '核心與體態調整', durationmin: 60, price: 6500, status: 'active', coaches: ['李教練', '張教練'] },
  { courseid: 5, coursename: '皮拉提斯', coursetype: '小團體', description: '器械皮拉提斯', durationmin: 55, price: 7000, status: 'active', coaches: ['陳教練'] },
  { courseid: 6, coursename: 'TRX 懸吊', coursetype: '小團體', description: '懸吊式全身訓練', durationmin: 50, price: 4800, status: 'active', coaches: ['李教練'] },
  { courseid: 7, coursename: '拳擊有氧', coursetype: '團體課', description: '有氧拳擊燃脂', durationmin: 50, price: 3200, status: 'active', coaches: ['林教練'] },
  { courseid: 8, coursename: 'HIIT 燃脂', coursetype: '團體課', description: '高強度間歇訓練', durationmin: 45, price: 3200, status: 'inactive', coaches: ['林教練'] },
];

/* ───────────── 預約流程 ───────────── */

const slotIndex = new Map<number, { membercourseid: number; date: string; hour: number; status: SlotStatus }>();
const bookedByMe = new Set<number>();

export function mockAvailableDates(): string[] {
  const out: string[] = [];
  for (let i = 0; out.length < 24; i++) {
    const d = addDaysISO(i);
    if (parseDate(d).getDay() !== 0) out.push(d); // 週日公休
  }
  return out;
}

export function mockSlots(membercourseid: number, date: string): ScheduleSlot[] {
  const rand = seeded(hash(`${date}#${membercourseid}`));
  const nowHour = new Date().getHours();
  return Array.from({ length: 13 }, (_, i) => {
    const hour = 9 + i;
    const scheduleid = Number(`${membercourseid}${date.slice(5).replace('-', '')}${String(hour).padStart(2, '0')}`);
    const r = rand();
    let status: SlotStatus = hour === 12 ? 'closed' : r < 0.45 ? 'available' : r < 0.8 ? 'booked' : 'private';
    if (date === todayISO() && hour <= nowHour && status === 'available') status = 'closed';
    slotIndex.set(scheduleid, { membercourseid, date, hour, status });
    if (bookedByMe.has(scheduleid)) status = 'booked';
    return { scheduleid, starttime: hh(hour), endtime: hh(hour + 1), status };
  });
}

/** 模擬 POST /booking 的規則：堂數要夠、時段要 available、不能重複預約 */
export function mockCreateBooking(req: BookingRequest): BookingResult {
  const course = mockMemberCourses.find((c) => c.membercourseid === req.membercourseid);
  if (!course) throw new ApiError(400, '找不到這門課程');
  if (course.remainingsessions <= 0) throw new ApiError(400, '剩餘堂數不足');
  const slot = slotIndex.get(req.scheduleid);
  if (!slot || slot.membercourseid !== req.membercourseid) throw new ApiError(400, '找不到這個時段');
  if (slot.status !== 'available' || bookedByMe.has(req.scheduleid)) throw new ApiError(400, '此時段已被預約');

  bookedByMe.add(req.scheduleid);
  course.remainingsessions -= 1;
  const result: BookingResult = {
    bookingid: 501 + mockBookings.length,
    coursename: course.coursename,
    coachname: course.coachname,
    classdate: slot.date,
    starttime: hh(slot.hour),
    endtime: hh(slot.hour + 1),
    classroom: ROOM[course.coursename] ?? 'A 館',
    bookingstatus: 'booked',
  };
  mockBookings.push(result);
  return result;
}

/* ───────────── 教練與全館排課 ───────────── */

export const mockCoaches: CoachInfo[] = [
  { coachid: 1, coachname: '王教練' },
  { coachid: 2, coachname: '李教練' },
  { coachid: 3, coachname: '陳教練' },
  { coachid: 4, coachname: '林教練' },
  { coachid: 5, coachname: '張教練' },
];

const COACH_COURSES: Record<number, string[]> = {
  2: ['體態雕塑', '一對一重訓', 'TRX 懸吊'],
  3: ['伸展放鬆', '皮拉提斯'],
  4: ['拳擊有氧', '一對一重訓', 'HIIT 燃脂'],
  5: ['增肌計畫', '一對一重訓', '體態雕塑'],
};
export const STUDENTS = ['林雅婷', '張志豪', '陳怡君', '黃冠宇', '吳佩珊', '劉家豪', '蔡宜蓁', '楊承翰', '許雅雯', '鄭宇軒',
  '謝佳穎', '郭俊宏', '洪詩涵', '曾柏翰', '邱心怡', '廖子晴', '周彥廷', '葉欣妤', '蘇冠廷', '江品妍'];

/** 王教練（coachid 1）固定的一天，方便對照教練端畫面 */
const COACH1_PLAN: Record<number, [SlotStatus, string?, string?]> = {
  7: ['booked', '林雅婷', '一對一重訓'], 8: ['available'], 9: ['booked', '張志豪', '增肌計畫'],
  10: ['booked', '陳怡君', '一對一重訓'], 11: ['available'], 12: ['closed'], 13: ['closed'],
  14: ['booked', '黃冠宇', '一對一重訓'], 15: ['private'], 16: ['available'],
  17: ['booked', '吳佩珊', '增肌計畫'], 18: ['booked', '劉家豪', '一對一重訓'],
  19: ['booked', '王小明', '一對一重訓'], 20: ['available'], 21: ['closed'],
};

export function mockGymDay(date: string): DayScheduleItem[] {
  const rand = seeded(hash(date));
  const rows: DayScheduleItem[] = [];
  let scheduleid = 1000;
  for (const coach of mockCoaches) {
    const pool = [...STUDENTS].sort(() => rand() - 0.5);
    const start = [7, 7, 8, 9][Math.floor(rand() * 4)];
    const end = [20, 21, 22][Math.floor(rand() * 3)];
    for (let hour = 7; hour < 22; hour++) {
      scheduleid += 1;
      let plan: [SlotStatus, string?, string?];
      if (coach.coachid === 1) plan = COACH1_PLAN[hour];
      else if (hour < start || hour >= end || hour === 12) plan = ['closed'];
      else {
        const r = rand();
        const courses = COACH_COURSES[coach.coachid];
        plan = r < 0.55
          ? ['booked', pool.pop(), courses[Math.floor(rand() * courses.length)]]
          : r < 0.65 ? ['private'] : ['available'];
      }
      const booked = plan[0] === 'booked';
      rows.push({
        scheduleid,
        coachid: coach.coachid,
        coachname: coach.coachname,
        classdate: date,
        starttime: hh(hour),
        endtime: hh(hour + 1),
        status: plan[0],
        membername: booked ? plan[1] ?? null : null,
        coursename: booked ? plan[2] ?? null : null,
      });
    }
  }
  return rows;
}

const coachCancelled = new Set<number>();

export function mockCoachSchedules(date: string, coachid = 1): CoachScheduleItem[] {
  return mockGymDay(date)
    .filter((r) => r.coachid === coachid && r.status === 'booked' && !coachCancelled.has(r.scheduleid))
    .map((r) => ({
      bookingid: 9000 + r.scheduleid,
      scheduleid: r.scheduleid,
      coursename: r.coursename ?? '',
      studentname: r.membername ?? '',
      starttime: r.starttime,
      endtime: r.endtime,
    }));
}

export function mockCoachDashboard(date: string): CoachDashboard {
  const list = mockCoachSchedules(date);
  return { todayCourseCount: list.length, todayStudentCount: new Set(list.map((r) => r.studentname)).size };
}

/** 模擬 PUT /coaches/{bookingid}/coach-cancel */
export function mockCoachCancel(bookingid: number): string {
  coachCancelled.add(bookingid - 9000);
  return '教練代取消成功';
}

function findMyBooking(bookingid: number): BookingResult {
  const b = mockBookings.find((x) => x.bookingid === bookingid);
  if (!b) throw new ApiError(400, '找不到此預約，或此預約不屬於目前的會員');
  if (b.bookingstatus !== 'booked') throw new ApiError(400, '此預約目前無法修改');
  return b;
}

/** 模擬 PUT /booking/{id}/cancel */
export function mockCancelBooking(bookingid: number): string {
  const b = findMyBooking(bookingid);
  b.bookingstatus = 'cancelled';
  return '取消預約成功';
}

/** 模擬 PUT /booking/{id}/reschedule：換到新時段 */
export function mockRescheduleBooking(bookingid: number, newScheduleid: number): string {
  const b = findMyBooking(bookingid);
  const slot = slotIndex.get(newScheduleid);
  if (!slot) throw new ApiError(400, '找不到新的課表');
  if (slot.status !== 'available' || bookedByMe.has(newScheduleid)) throw new ApiError(400, '新的時段已經被其他會員預約');
  bookedByMe.add(newScheduleid);
  b.classdate = slot.date;
  b.starttime = hh(slot.hour);
  b.endtime = hh(slot.hour + 1);
  return '修改預約成功';
}
