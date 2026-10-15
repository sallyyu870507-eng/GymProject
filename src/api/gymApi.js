import { http } from "./http.js";

// 一個函式對應一支後端 API（對照後端 Controller）
export const gymApi = {
  // 登入：送帳號密碼，後端建立 Session 並回傳 { role, name }
  // role 必須是 member / coach / admin。後端實際路徑或欄位不同時，只改這一個函式。
  login: (account, password) => http("/auth/login", { method: "POST", body: { account, password } }),

  // 會員端 ReservationOptionController / BookingController
  myCourses:      ()         => http("/members/courses"),
  availableDates: id         => http(`/members/courses/${id}/available-dates`),
  slots:          (id, date) => http(`/members/courses/${id}/schedules?date=${date}`),
  createBooking:  ({ membercourseid, scheduleid, note }) =>
    http("/booking", { method: "POST", body: { membercourseid, scheduleid, note } }),

  // 教練端 CoachController
  coachSchedules: date => http(`/coaches/schedules?date=${date}`),
  coachDashboard: date => http(`/coaches/dashboard?date=${date}`),

  // 管理端 AdminScheduleController
  adminCoaches: ()   => http("/admin/schedules/coaches"),
  adminDay:     date => http(`/admin/schedules/day?date=${date}`),
};
