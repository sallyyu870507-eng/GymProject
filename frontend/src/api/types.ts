/**
 * 前後端共用的資料格式。
 * 欄位名稱完全照《POWER GYM 預約系統 API 規格書》v0.1（後端 DTO 是全小寫）。
 * 後端改了 DTO，就改這裡，TypeScript 會指出所有要跟著改的畫面。
 */

export type Role = 'member' | 'coach' | 'admin';

/**
 * 1.2 時段狀態。
 * 注意：資料表 classschedule.status 預設值是 'open'，規格書寫的是 'available'。
 * 前端在 API 層把 'open' 統一轉成 'available'（見 api/normalize.ts），兩種寫法都能用。
 */
export type SlotStatus = 'available' | 'booked' | 'closed' | 'private';

export type BookingStatus = 'booked' | 'completed' | 'cancelled';

/* ───────────── 會員端（規格書第 4 章） ───────────── */

/** 4.1 GET /members/courses */
export interface MemberCourse {
  membercourseid: number;
  courseid: number;
  coursename: string;
  coachid: number;
  coachname: string;
  remainingsessions: number;
  /** membercourse.totalsessions：規格書 DTO 沒有，建議後端補上（畫進度條用） */
  totalsessions?: number;
  /** membercourse.purchasedate：規格書 DTO 沒有，建議後端補上 */
  purchasedate?: string;
}

/** 4.3 GET /members/courses/{id}/schedules?date= */
export interface ScheduleSlot {
  scheduleid: number;
  starttime: string; // "09:00:00"
  endtime: string;
  status: SlotStatus;
}

/** 4.4 POST /booking 送出 */
export interface BookingRequest {
  membercourseid: number;
  scheduleid: number;
  note?: string;
}

/** PUT /booking/{id}/reschedule、/coaches/{id}/reschedule 送出 */
export interface RescheduleRequest {
  newScheduleid: number;
}

/** 4.4 POST /booking 回傳；也當作「我的預約紀錄」的一筆 */
export interface BookingResult {
  bookingid: number;
  coursename: string;
  coachname: string;
  classdate: string; // "2026-10-15"
  starttime: string;
  endtime: string;
  classroom: string;
  bookingstatus: BookingStatus | string;
}

/* ───────────── 教練端（規格書第 5 章） ───────────── */

/** 5.1 GET /coaches/schedules?date= */
export interface CoachScheduleItem {
  /** feature/booking-fangyu 新增：教練代取消 / 改期要用 */
  bookingid: number;
  scheduleid: number;
  coursename: string;
  studentname: string;
  starttime: string;
  endtime: string;
}

/** 5.2 GET /coaches/dashboard?date=（注意：這支是駝峰命名） */
export interface CoachDashboard {
  todayCourseCount: number;
  todayStudentCount: number;
}

/* ───────────── 管理端（規格書第 6 章） ───────────── */

/** 6.1 GET /admin/schedules/coaches */
export interface CoachInfo {
  coachid: number;
  coachname: string;
}

/** 6.2 GET /admin/schedules/day?date= */
export interface DayScheduleItem {
  scheduleid: number;
  coachid: number;
  coachname: string;
  classdate: string;
  starttime: string;
  endtime: string;
  status: SlotStatus;
  membername: string | null;
  coursename: string | null;
}

/* ───────────── 會員管理（feature/test-chiaying 分支） ───────────── */

/** 後端多數 API 的回傳：{ success, message }；DTO 驗證失敗時是 { success:false, errors:{欄位:訊息} } */
export interface ApiResult {
  success: boolean;
  message?: string;
  errors?: Record<string, string>;
}

/** GET /api/user：目前登入者（ApiUserController） */
export interface CurrentUser {
  username: string;
  name: string;
  role: Role;
}

export type AccountStatus = 'active' | 'inactive';
export type MemberStatusFilter = 'all' | AccountStatus;

/** MemberCourseDTO */
export interface MemberCourseBrief {
  courseid?: number; // 教練端才有
  coursename: string;
  remainingsessions: number;
}

/** MemberListDTO：會員清單的一列 */
export interface MemberListItem {
  accountid: number;
  memberid: number;
  memberno: string;
  name: string;
  gender: string | null;
  phone: string;
  status: AccountStatus | string;
  courses: MemberCourseBrief[];
}

/** AccountService.findAllMembers / CoachMemberService.findCoachMembers 回傳的 Map */
export interface MemberListPage {
  members: MemberListItem[];
  currentPage: number;
  pageSize: number;
  totalPages: number;
  totalElements: number;
  hasNext: boolean;
  hasPrev: boolean;
}

export interface MemberListQuery {
  page: number;
  size: number;
  keyword?: string;
  /** 只有管理員端可用 */
  status?: MemberStatusFilter;
}

/** RegisterDTO：POST /api/admin/members */
export interface RegisterRequest {
  username: string; // 4~20 位英數
  password: string; // 至少 4 字元
  name: string;
  gender?: string;
  phone: string; // 09 開頭 10 碼
  email?: string;
  birthday: string; // yyyy-MM-dd，須早於今天
}

/** MemberUpdateDTO：管理員 GET /{memberid}、PUT /update/{memberid} */
export interface MemberUpdateRequest {
  username: string;
  name: string;
  phone: string;
  email?: string | null;
}

/** CoachMemberUpdateDTO：教練 GET /{memberid}、PUT /update/{memberid} */
export interface CoachMemberUpdateRequest {
  name: string;
  phone: string;
  email?: string | null;
}

/* ───────────── 後端尚未提供 API 的資料（先用示範資料） ─────────────
 * 欄位名稱已對齊最終資料表（gymproject），後端寫 DTO 時沿用同樣名稱即可直接串接。
 */

/** member 資料表：會員個人資料（系統沒有會籍方案 / 到期日的資料表） */
export interface MemberProfile {
  memberid: number;
  memberno: string;
  name: string;
  gender: string;
  phone: string;
  email: string;
  birthday: string; // yyyy-MM-dd
  avatarurl: string | null;
  status: string; // active / inactive
}

/** 由 attendance.checkintime 依週統計的到館次數 */
export interface WeeklyAttendance {
  week: string; // 該週週一
  checkins: number;
}

/** inbodyrecords 資料表 */
export interface InBodyRecord {
  inbodyid: number;
  recorddate: string; // yyyy-MM-dd
  weight: number; // 體重 kg
  bodyfatpct: number; // 體脂率 %
  musclemass: number; // 肌肉量 kg
}

/** course 資料表；coaches 由 coachcourse 關聯查出 */
export interface CourseCatalogItem {
  courseid: number;
  coursename: string;
  coursetype: string;
  description: string;
  durationmin: number;
  price: number;
  status: string;
  /** coachcourse JOIN coach 的教練姓名，後端可選擇是否回傳 */
  coaches?: string[];
}

/* ───────────── 前端自己用 ───────────── */

export interface SessionUser {
  role: Role;
  name: string;
  username?: string;
}
