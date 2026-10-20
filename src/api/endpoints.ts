/**
 * 所有後端網址都在這裡，後端改路徑只要改這一個檔案。
 * ✅ = 後端已實作（註明來源）　TODO = 規格書還沒有、前端先預留
 */
export const ENDPOINTS = {
  auth: {
    login: '/login', // ✅ LoginController：表單 username / password，成功後 redirect
    logout: '/logout', // ✅ LoginController
    me: '/api/user', // ✅ ApiUserController：{ username, name, role }
    testLogin: (role: string) => `/session-test/login-${role}`, // 規格書第 3 章，開發用
  },

  member: {
    // ✅ ReservationOptionController（feature/booking-fangyu）
    courses: '/members/courses', // 規格書 4.1
    availableDates: (membercourseid: number) => `/members/courses/${membercourseid}/available-dates`, // 4.2
    schedules: (membercourseid: number) => `/members/courses/${membercourseid}/schedules`, // 4.3
    bookings: '/booking/my', // ✅ BookingController：會員自己的預約紀錄
    profile: '/members/profile', // TODO 會籍資料
    attendance: '/members/attendance', // TODO 每週到館次數
    inbody: '/members/inbody', // TODO InBody 檢測紀錄
  },

  // ✅ BookingController（feature/booking-fangyu）
  booking: {
    create: '/booking', // POST 規格書 4.4
    cancel: (bookingid: number) => `/booking/${bookingid}/cancel`, // PUT 會員取消
    reschedule: (bookingid: number) => `/booking/${bookingid}/reschedule`, // PUT { newScheduleid } 會員改期
  },

  courses: {
    catalog: '/courses', // TODO 課程目錄
  },

  coach: {
    // ✅ BookingCoachController（feature/booking-fangyu）
    schedules: '/coaches/schedules', // 規格書 5.1
    dashboard: '/coaches/dashboard', // 規格書 5.2
    cancel: (bookingid: number) => `/coaches/${bookingid}/coach-cancel`, // PUT 教練代取消
    reschedule: (bookingid: number) => `/coaches/${bookingid}/reschedule`, // PUT { newScheduleid } 教練改期
    gymDay: '/coaches/schedules/gym', // TODO 教練端的全館課表（/admin/schedules/day 只開放管理員）

    // ✅ CoachMemberController（feature/test-chiaying）
    members: '/api/coach/members', // GET ?page&size&keyword
    member: (memberid: number) => `/api/coach/members/${memberid}`, // GET
    updateMember: (memberid: number) => `/api/coach/members/update/${memberid}`, // PUT
  },

  admin: {
    // ✅ AdminScheduleController（feature/booking-fangyu）
    coaches: '/admin/schedules/coaches', // 規格書 6.1
    daySchedule: '/admin/schedules/day', // 規格書 6.2

    // ✅ AdminController（feature/test-chiaying）
    members: '/api/admin/members', // GET ?page&size&status&keyword ／ POST 新增
    member: (memberid: number) => `/api/admin/members/${memberid}`, // GET 編輯用資料
    updateMember: (memberid: number) => `/api/admin/members/update/${memberid}`, // PUT
    deactivate: (accountid: number) => `/api/admin/members/del/${accountid}`, // DELETE（軟刪除）
    reactivate: (accountid: number) => `/api/admin/members/${accountid}/reactivate`, // PATCH
  },
} as const;
