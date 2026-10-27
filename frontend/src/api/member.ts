import { http } from './client';
import { ENDPOINTS } from './endpoints';
import { withMock } from './mock';
import type {
  BookingRequest,
  BookingResult,
  CourseCatalogItem,
  InBodyRecord,
  MemberCourse,
  MemberProfile,
  RescheduleRequest,
  ScheduleSlot,
  WeeklyAttendance,
} from './types';
import * as mock from '../mocks/data';
import { normalizeBookingStatus, withNormalizedBooking, withNormalizedStatus } from './normalize';

const E = ENDPOINTS.member;

export const memberApi = {
  /** 4.1 已購買且仍有剩餘堂數的課程 */
  courses: (signal?: AbortSignal) =>
    withMock(() => http.get<MemberCourse[]>(E.courses, undefined, signal), () => mock.mockMemberCourses),

  /** 4.2 某課程的可預約日期 */
  availableDates: (membercourseid: number, signal?: AbortSignal) =>
    withMock(
      () => http.get<string[]>(E.availableDates(membercourseid), undefined, signal),
      () => mock.mockAvailableDates(),
    ),

  /** 4.3 某天的所有時段與狀態 */
  schedules: (membercourseid: number, date: string, signal?: AbortSignal) =>
    withMock(
      async () => withNormalizedStatus(await http.get<ScheduleSlot[]>(E.schedules(membercourseid), { date }, signal)),
      () => mock.mockSlots(membercourseid, date),
    ),

  /** 我的預約紀錄：GET /booking/my */
  bookings: (signal?: AbortSignal) =>
    withMock(
      async () => withNormalizedBooking(await http.get<BookingResult[]>(E.bookings, undefined, signal)),
      () => mock.mockBookings,
    ),

  /* ↓ 後端還沒有這些 API：第三個參數 false = 一律用示範資料。做好後改成 true。 */

  /** member 資料表的個人資料 */
  profile: (signal?: AbortSignal) =>
    withMock(() => http.get<MemberProfile>(E.profile, undefined, signal), () => mock.mockProfile, false),

  /** 由 attendance.checkintime 統計 */
  attendance: (signal?: AbortSignal) =>
    withMock(() => http.get<WeeklyAttendance[]>(E.attendance, undefined, signal), () => mock.mockAttendance, false),

  /** inbodyrecords 資料表 */
  inbody: (signal?: AbortSignal) =>
    withMock(() => http.get<InBodyRecord[]>(E.inbody, undefined, signal), () => mock.mockInBody, false),
};

export const bookingApi = {
  /** 4.4 建立預約；失敗時 error.message 就是後端回的文字（例如「此時段已被預約」） */
  create: (req: BookingRequest) =>
    withMock(
      async () => {
        // booking.note 是 NOT NULL，後端不會補預設值，所以沒填也要送空字串
        const r = await http.post<BookingResult>(ENDPOINTS.booking.create, { ...req, note: req.note ?? '' });
        return { ...r, bookingstatus: normalizeBookingStatus(r.bookingstatus) };
      },
      () => mock.mockCreateBooking(req),
    ),

  /** 會員取消自己的預約；成功回傳文字「取消預約成功」 */
  cancel: (bookingid: number) =>
    withMock(
      () => http.put<string>(ENDPOINTS.booking.cancel(bookingid)),
      () => mock.mockCancelBooking(bookingid),
    ),

  /** 會員改期：只能換同課程、同教練、明天以後的 open 時段 */
  reschedule: (bookingid: number, newScheduleid: number) =>
    withMock(
      () => http.put<string>(ENDPOINTS.booking.reschedule(bookingid), { newScheduleid } satisfies RescheduleRequest),
      () => mock.mockRescheduleBooking(bookingid, newScheduleid),
    ),
};

export const catalogApi = {
  list: (signal?: AbortSignal) =>
    withMock(
      () => http.get<CourseCatalogItem[]>(ENDPOINTS.courses.catalog, undefined, signal),
      () => mock.mockCatalog,
      false,
    ),
};
