import { http } from './client';
import { ENDPOINTS } from './endpoints';
import { withMock } from './mock';
import type {
  ApiResult,
  CoachDashboard,
  CoachMemberUpdateRequest,
  CoachScheduleItem,
  DayScheduleItem,
  MemberListPage,
  MemberListQuery,
  RescheduleRequest,
} from './types';
import * as mock from '../mocks/data';
import { withNormalizedStatus } from './normalize';
import * as memberMock from '../mocks/members';

const E = ENDPOINTS.coach;

/** 教練編號由後端 Session 的 coachid 取得，前端不用傳 */
export const coachApi = {
  /** 規格書 5.1 教練某天已被預約的課表 */
  schedules: (date: string, signal?: AbortSignal) =>
    withMock(() => http.get<CoachScheduleItem[]>(E.schedules, { date }, signal), () => mock.mockCoachSchedules(date)),

  /** 規格書 5.2 教練某天的課程數與學員數 */
  dashboard: (date: string, signal?: AbortSignal) =>
    withMock(() => http.get<CoachDashboard>(E.dashboard, { date }, signal), () => mock.mockCoachDashboard(date)),

  /** 教練代取消學員的預約；成功回傳文字「教練代取消成功」 */
  cancelBooking: (bookingid: number) =>
    withMock(() => http.put<string>(E.cancel(bookingid)), () => mock.mockCoachCancel(bookingid)),

  /**
   * 教練幫學員改期。後端已完成，但教練端目前沒有「查自己可用時段」的 API，
   * 畫面還無法讓教練挑新時段，所以先只提供函式，等後端補 API 後再接畫面。
   */
  reschedule: (bookingid: number, newScheduleid: number) =>
    withMock(
      () => http.put<string>(E.reschedule(bookingid), { newScheduleid } satisfies RescheduleRequest),
      () => '修改預約成功',
    ),

  /**
   * 全館教練排課表（規格書 7-4 待補）。
   * 後端的 /admin/schedules/day 只允許管理員，教練呼叫會失敗；
   * 等後端開一支教練可用的，或放寬權限後，把 false 改成 true。
   */
  gymDay: (date: string, signal?: AbortSignal) =>
    withMock(async () => withNormalizedStatus(await http.get<DayScheduleItem[]>(E.gymDay, { date }, signal)), () => mock.mockGymDay(date), false),

  /* ───── CoachMemberController（/api/coach/members） ───── */

  /** 我的學員：只會回傳有買這位教練課程的會員 */
  members: (q: MemberListQuery, signal?: AbortSignal) =>
    withMock(
      () => http.get<MemberListPage>(E.members, { page: q.page, size: q.size, keyword: q.keyword ?? '' }, signal),
      () => memberMock.mockCoachMembers(q),
    ),

  /** 取得學員可編輯的資料（CoachMemberUpdateDTO：name / phone / email） */
  getMember: (memberid: number, signal?: AbortSignal) =>
    withMock(
      () => http.get<CoachMemberUpdateRequest>(E.member(memberid), undefined, signal),
      () => memberMock.mockCoachGetMember(memberid),
    ),

  updateMember: (memberid: number, dto: CoachMemberUpdateRequest) =>
    withMock(
      () => http.put<ApiResult>(E.updateMember(memberid), dto),
      () => memberMock.mockCoachUpdateMember(memberid, dto),
    ),
};
