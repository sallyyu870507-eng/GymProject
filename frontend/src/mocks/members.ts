/**
 * 會員管理的示範資料：模擬 AccountService / CoachMemberService 的行為，
 * 包含 DTO 驗證（400 errors）、帳號重複（409）、停用 / 恢復的狀態檢查。
 */
import { ApiError } from '../api/client';
import type {
  ApiResult,
  CoachMemberUpdateRequest,
  MemberListItem,
  MemberListPage,
  MemberListQuery,
  MemberUpdateRequest,
  RegisterRequest,
} from '../api/types';
import { todayISO } from '../utils/format';
import { STUDENTS } from './data';

interface MockMember extends MemberListItem {
  username: string;
  email: string | null;
  /** 示範用：這位會員有買哪些教練的課 */
  coachids: number[];
}

const COURSE_POOL: [string, number][] = [
  ['一對一重訓', 1],
  ['體態雕塑', 2],
  ['伸展放鬆', 3],
  ['拳擊有氧', 4],
  ['增肌計畫', 5],
];

const members: MockMember[] = ['王小明', ...STUDENTS, '林志明', '陳美玲'].map((name, i) => {
  const memberid = i + 1;
  const picks = [COURSE_POOL[i % 5], ...(i % 3 === 0 ? [COURSE_POOL[(i + 2) % 5]] : [])];
  return {
    accountid: 100 + memberid,
    memberid,
    memberno: `M${String(memberid).padStart(6, '0')}`,
    username: `member${String(memberid).padStart(3, '0')}`,
    name,
    gender: i % 2 ? '女' : '男',
    phone: `09${String(12345678 + i * 7919).slice(0, 8)}`,
    email: `member${memberid}@example.com`,
    status: i % 7 === 5 ? 'inactive' : 'active',
    courses: picks.map(([coursename, coachid], k) => ({
      courseid: coachid,
      coursename,
      remainingsessions: (i * 3 + k * 5) % 12,
    })),
    coachids: picks.map(([, coachid]) => coachid),
  };
});

const toItem = ({ username: _u, email: _e, coachids: _c, ...item }: MockMember): MemberListItem => item;

function paginate(list: MockMember[], { page, size }: MemberListQuery): MemberListPage {
  const totalPages = Math.max(1, Math.ceil(list.length / size));
  return {
    members: list.slice(page * size, page * size + size).map(toItem),
    currentPage: page,
    pageSize: size,
    totalPages,
    totalElements: list.length,
    hasNext: page + 1 < totalPages,
    hasPrev: page > 0,
  };
}

const matches = (m: MockMember, keyword?: string) => {
  const k = keyword?.trim();
  return !k || [m.name, m.phone, m.memberno, m.username].some((v) => v.includes(k));
};

function find(memberid: number) {
  const m = members.find((x) => x.memberid === memberid);
  if (!m) throw new ApiError(404, '找不到會員');
  return m;
}

function findByAccount(accountid: number) {
  const m = members.find((x) => x.accountid === accountid);
  if (!m) throw new ApiError(404, '找不到該帳號');
  return m;
}

/** 照後端 DTO 的 @NotBlank / @Pattern / @Email / @Past 規則檢查 */
function validate(dto: Partial<Record<keyof RegisterRequest, string | null>>, fields: (keyof RegisterRequest)[]) {
  const errors: Record<string, string> = {};
  const has = (k: keyof RegisterRequest) => fields.includes(k);
  if (has('username')) {
    if (!dto.username?.trim()) errors.username = '使用者名稱不能為空';
    else if (!/^[A-Za-z0-9]{4,20}$/.test(dto.username)) errors.username = '帳號必須為4~20位英文字母或數字';
  }
  if (has('password') && (!dto.password || dto.password.length < 4)) errors.password = '密碼至少為四字元';
  if (has('name') && !dto.name?.trim()) errors.name = '姓名不能為空';
  if (has('phone')) {
    if (!dto.phone?.trim()) errors.phone = '手機不能為空';
    else if (!/^09\d{8}$/.test(dto.phone)) errors.phone = '手機號碼格式錯誤';
  }
  if (has('email') && dto.email && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(dto.email)) errors.email = '必須是格式正確的電子郵件地址';
  if (has('birthday')) {
    if (!dto.birthday) errors.birthday = '請填寫生日';
    else if (dto.birthday >= todayISO()) errors.birthday = '生日須早於今日';
  }
  if (Object.keys(errors).length) throw new ApiError(400, Object.values(errors).join('、'), { success: false, errors });
}

const ok = (message: string): ApiResult => ({ success: true, message });

/* ───────────── 管理員 ───────────── */

export function mockAdminMembers(q: MemberListQuery): MemberListPage {
  const status = q.status ?? 'all';
  const list = members.filter((m) => (status === 'all' || m.status === status) && matches(m, q.keyword));
  return paginate(list, q);
}

export function mockAdminGetMember(memberid: number): MemberUpdateRequest {
  const m = find(memberid);
  return { username: m.username, name: m.name, phone: m.phone, email: m.email };
}

export function mockAdminCreateMember(dto: RegisterRequest): ApiResult {
  validate(dto, ['username', 'password', 'name', 'phone', 'email', 'birthday']);
  if (members.some((m) => m.username === dto.username)) throw new ApiError(400, '帳號已存在，請更換其他名稱');
  const memberid = members.length + 1;
  members.push({
    accountid: 100 + memberid,
    memberid,
    memberno: `M${String(memberid).padStart(6, '0')}`,
    username: dto.username,
    name: dto.name,
    gender: dto.gender || null,
    phone: dto.phone,
    email: dto.email || null,
    status: 'active',
    courses: [],
    coachids: [],
  });
  return ok('新增會員成功');
}

export function mockAdminUpdateMember(memberid: number, dto: MemberUpdateRequest): ApiResult {
  validate(dto, ['username', 'name', 'phone', 'email']);
  const m = find(memberid);
  if (m.username !== dto.username && members.some((x) => x.username === dto.username)) {
    throw new ApiError(404, '帳號已被使用');
  }
  Object.assign(m, { username: dto.username, name: dto.name, phone: dto.phone, email: dto.email || null });
  return ok('會員資料更新成功');
}

export function mockDeactivate(accountid: number): ApiResult {
  const m = findByAccount(accountid);
  if (m.status === 'inactive') throw new ApiError(500, '系統發生錯誤請稍後再試。');
  m.status = 'inactive';
  return ok('帳號停用成功');
}

export function mockReactivate(accountid: number): ApiResult {
  const m = findByAccount(accountid);
  if (m.status === 'active') throw new ApiError(500, '系統發生錯誤請稍後再試。');
  m.status = 'active';
  return ok('會員恢復成功');
}

/* ───────────── 教練：只看得到有買自己課的學員 ───────────── */

const MOCK_COACH_ID = 1;

function ownStudent(memberid: number) {
  const m = find(memberid);
  if (!m.coachids.includes(MOCK_COACH_ID)) throw new ApiError(404, '沒有權限查看此學員');
  return m;
}

export function mockCoachMembers(q: MemberListQuery): MemberListPage {
  const list = members
    .filter((m) => m.coachids.includes(MOCK_COACH_ID) && matches(m, q.keyword))
    .map((m) => ({ ...m, courses: m.courses.filter((c) => c.courseid === MOCK_COACH_ID) }));
  return paginate(list, q);
}

export function mockCoachGetMember(memberid: number): CoachMemberUpdateRequest {
  const m = ownStudent(memberid);
  return { name: m.name, phone: m.phone, email: m.email };
}

export function mockCoachUpdateMember(memberid: number, dto: CoachMemberUpdateRequest): ApiResult {
  validate(dto, ['name', 'phone', 'email']);
  const m = ownStudent(memberid);
  Object.assign(m, { name: dto.name, phone: dto.phone, email: dto.email || null });
  return ok('會員資料更新成功');
}
