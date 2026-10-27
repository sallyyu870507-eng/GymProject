import { http } from './client';
import { ENDPOINTS } from './endpoints';
import { withMock } from './mock';
import type {
  ApiResult,
  CoachInfo,
  DayScheduleItem,
  MemberListPage,
  MemberListQuery,
  MemberUpdateRequest,
  RegisterRequest,
} from './types';
import * as mock from '../mocks/data';
import { withNormalizedStatus } from './normalize';
import * as memberMock from '../mocks/members';

const E = ENDPOINTS.admin;

/** 空字串的選填欄位改成不送，避免觸發後端 @Email 之類的驗證 */
function compact<T extends object>(obj: T): T {
  return Object.fromEntries(Object.entries(obj).filter(([, v]) => v !== '' && v !== undefined)) as T;
}

export const adminApi = {
  /** 規格書 6.1 取得所有教練 */
  coaches: (signal?: AbortSignal) =>
    withMock(() => http.get<CoachInfo[]>(E.coaches, undefined, signal), () => mock.mockCoaches),

  /** 規格書 6.2 某天全館所有教練的排課 */
  daySchedule: (date: string, signal?: AbortSignal) =>
    withMock(async () => withNormalizedStatus(await http.get<DayScheduleItem[]>(E.daySchedule, { date }, signal)), () => mock.mockGymDay(date)),

  /* ───── AdminController（/api/admin/members） ───── */

  /** 會員清單：分頁 + 狀態篩選（all/active/inactive）+ 關鍵字 */
  members: (q: MemberListQuery, signal?: AbortSignal) =>
    withMock(
      () =>
        http.get<MemberListPage>(
          E.members,
          { page: q.page, size: q.size, status: q.status ?? 'all', keyword: q.keyword ?? '' },
          signal,
        ),
      () => memberMock.mockAdminMembers(q),
    ),

  /** 新增會員（RegisterDTO） */
  createMember: (dto: RegisterRequest) =>
    withMock(() => http.post<ApiResult>(E.members, compact(dto)), () => memberMock.mockAdminCreateMember(dto)),

  /** 取得編輯用的會員資料（MemberUpdateDTO） */
  getMember: (memberid: number, signal?: AbortSignal) =>
    withMock(
      () => http.get<MemberUpdateRequest>(E.member(memberid), undefined, signal),
      () => memberMock.mockAdminGetMember(memberid),
    ),

  /** 更新會員資料 */
  updateMember: (memberid: number, dto: MemberUpdateRequest) =>
    withMock(
      () => http.put<ApiResult>(E.updateMember(memberid), dto),
      () => memberMock.mockAdminUpdateMember(memberid, dto),
    ),

  /** 停用（軟刪除）：注意參數是 accountid，不是 memberid */
  deactivate: (accountid: number) =>
    withMock(() => http.del<ApiResult>(E.deactivate(accountid)), () => memberMock.mockDeactivate(accountid)),

  /** 恢復停用的會員：參數是 accountid */
  reactivate: (accountid: number) =>
    withMock(() => http.patch<ApiResult>(E.reactivate(accountid)), () => memberMock.mockReactivate(accountid)),
};
