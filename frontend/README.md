# POWER GYM Dashboard（React + TypeScript）

學員端、教練端、管理員端的前端。版面依 Figma 線框稿，API 欄位依《POWER GYM 預約系統 API 規格書》v0.1。

- 技術：React 18、TypeScript、Vite、React Router、Recharts
- 預設是「示範資料模式」，不用後端也能跑；改一行設定就接上 Spring Boot

## 快速開始

需要 Node.js 18 以上。

```bash
npm install
npm run dev
```

打開 http://localhost:5173 ，登入頁按「學員 / 教練 / 管理員」就能直接進去看。

## 接上 Spring Boot 後端

1. 啟動後端（預設 `http://localhost:8080`）
2. 打開 `.env.development`，把 `VITE_USE_MOCK=true` 改成 `false`
3. 重新執行 `npm run dev`
4. 用資料庫裡的帳號密碼登入

後端 port 不是 8080 的話，改 `.env.development` 的 `VITE_PROXY_TARGET`。

### 為什麼不會遇到 CORS

`vite.config.ts` 把 `/api`、`/members`、`/coaches`、`/admin`、`/booking`、`/login` 等路徑轉送給後端，
瀏覽器以為前後端是同一個網址，所以：

- 不需要在後端加 `@CrossOrigin`
- 登入後的 `JSESSIONID` Cookie 會自動帶上，LoginInterceptor 認得你

後端新增其他開頭的路徑時，記得加到 `vite.config.ts` 的 `BACKEND_PATHS`。

## 專案結構

```
src/
├─ api/                 ← 所有跟後端有關的程式都在這裡
│  ├─ endpoints.ts        後端網址（改路徑只改這個檔）
│  ├─ types.ts            資料格式（對應後端 DTO）
│  ├─ client.ts           fetch 包裝：帶 Cookie、解析 JSON、統一錯誤、401 回登入頁
│  ├─ mock.ts             示範模式開關 withMock()
│  ├─ auth.ts             登入 / 登出
│  ├─ member.ts           會員端 API + 預約
│  ├─ coach.ts            教練端 API
│  └─ admin.ts            管理端 API
├─ mocks/data.ts        示範資料
├─ hooks/useApi.ts      呼叫 API 的 hook（loading / error / reload）
├─ auth/AuthContext.tsx 登入狀態、路由守衛
├─ components/          卡片、圖表、排課表等共用元件
├─ pages/
│  ├─ SignInPage.tsx
│  ├─ student/          學員端：總覽、課堂提醒、會員管理、InBody、課程管理、預約管理、新增預約
│  ├─ coach/            教練端：今日教學課表、全館教練排課表
│  └─ admin/            管理員端：會員清單
└─ styles.css           全部樣式（顏色在最上面的 :root）
```

## API 對照表

| 畫面 | API | 狀態 |
|---|---|---|
| 課程管理、新增預約 | `GET /members/courses` | 規格書 4.1 ✅ |
| 新增預約：選日期 | `GET /members/courses/{id}/available-dates` | 規格書 4.2 ✅ |
| 新增預約：選時段 | `GET /members/courses/{id}/schedules?date=` | 規格書 4.3 ✅ |
| 新增預約：送出 | `POST /booking` | 規格書 4.4 ✅ |
| 我的預約紀錄 | `GET /booking/my` | BookingController ✅ |
| 會員取消預約 | `PUT /booking/{bookingid}/cancel` | BookingController ✅ |
| 會員改期 | `PUT /booking/{bookingid}/reschedule`（`{ newScheduleid }`） | BookingController ✅ |
| 教練：今日課表 | `GET /coaches/schedules?date=` | 規格書 5.1 ✅ |
| 教練：統計 | `GET /coaches/dashboard?date=` | 規格書 5.2 ✅ |
| 教練：代取消 | `PUT /coaches/{bookingid}/coach-cancel` | BookingCoachController ✅ |
| 教練：改期 | `PUT /coaches/{bookingid}/reschedule` | 函式已接，畫面待後端補「教練可用時段」API |
| 管理員：全館排課 / 教練清單 | `GET /admin/schedules/day?date=`、`GET /admin/schedules/coaches` | AdminScheduleController ✅ |
| 登入 | `POST /login`（表單） | LoginController ✅ |
| 目前登入者 | `GET /api/user` | ApiUserController ✅ |
| 管理員：會員清單 | `GET /api/admin/members?page=&size=&status=&keyword=` | AdminController ✅ |
| 管理員：新增會員 | `POST /api/admin/members` | AdminController ✅ |
| 管理員：編輯會員 | `GET /api/admin/members/{memberid}`、`PUT /api/admin/members/update/{memberid}` | AdminController ✅ |
| 管理員：停用 / 恢復 | `DELETE /api/admin/members/del/{accountid}`、`PATCH /api/admin/members/{accountid}/reactivate` | AdminController ✅ |
| 教練：我的學員 | `GET /api/coach/members?page=&size=&keyword=` | CoachMemberController ✅ |
| 教練：編輯學員 | `GET /api/coach/members/{memberid}`、`PUT /api/coach/members/update/{memberid}` | CoachMemberController ✅ |
| 會籍資料 | `GET /members/profile` | ⏳ 待後端 |
| 每週到館 | `GET /members/attendance` | ⏳ 待後端 |
| InBody 紀錄 | `GET /members/inbody` | ⏳ 待後端 |
| 課程目錄 | `GET /courses` | ⏳ 待後端 |
| 教練：全館排課表 | `GET /coaches/schedules/gym?date=` | ⏳ 待後端（`/admin/schedules/day` 只開放管理員） |

⏳ 的 API 就算關掉示範模式也會繼續用示範資料，畫面不會壞。
後端做好之後，到 `src/api/` 找到那支，把 `withMock(...)` 最後的 `false` 刪掉，網址不同就改 `endpoints.ts`。

## 前端欄位與資料表對照（gymproject 最終結構）

後端寫 DTO 時沿用資料表的欄位名稱，前端就能直接接上，不用轉換。

| 前端型別（`src/api/types.ts`） | 資料表 | 欄位 |
|---|---|---|
| `MemberProfile` | member | memberid、memberno、name、gender、phone、email、birthday、avatarurl、status |
| `MemberCourse` | membercourse + course + coach | membercourseid、courseid、coursename、coachid、coachname、remainingsessions、totalsessions、purchasedate |
| `ScheduleSlot` / `DayScheduleItem` | classschedule | scheduleid、starttime、endtime、status（`open` 會自動轉成 `available`） |
| `BookingResult` | booking + classschedule | bookingid、classdate、starttime、endtime、classroom、bookingstatus |
| `InBodyRecord` | inbodyrecords | inbodyid、recorddate、weight、bodyfatpct、musclemass（體脂肪重由前端換算） |
| `WeeklyAttendance` | attendance | 依 checkintime 每週統計 |
| `CourseCatalogItem` | course + coachcourse | courseid、coursename、coursetype、description、durationmin、price、status、coaches |

## 新增一支 API 的步驟

以「取消預約 `PUT /booking/{id}/cancel`」為例：

1. `endpoints.ts` 加路徑：`cancel: (id: number) => \`/booking/${id}/cancel\``
2. `types.ts` 加回傳格式（如果有新的）
3. `member.ts` 的 `bookingApi` 加一個方法：
   ```ts
   cancel: (bookingid: number) =>
     withMock(() => http.put<BookingResult>(ENDPOINTS.booking.cancel(bookingid)), () => ({ ...假資料 })),
   ```
4. 畫面裡呼叫：`await bookingApi.cancel(id)`；錯誤訊息直接用 `err.message`

讀取資料用 hook：

```tsx
const courses = useApi((signal) => memberApi.courses(signal), []);

<AsyncView state={courses}>
  {(list) => list.map((c) => <div key={c.membercourseid}>{c.coursename}</div>)}
</AsyncView>
```

`AsyncView` 會自動處理讀取中、錯誤訊息與「重試」按鈕。

## 給後端的建議

1. **登入改回 JSON**：現在的 `/login` 回 redirect，前端只能看最後停在哪個網址判斷成功或失敗，再呼叫 `/api/user` 拿姓名。
   建議加一支 `POST /api/login` 直接回傳 `{ success, role, name }`。
2. **`/members/courses` 補 `totalsessions`、`expiredate`**：課程進度條需要總堂數。
3. **錯誤統一回 JSON**：`{ "message": "..." }`，前端會直接顯示 message。
4. **GlobalExceptionHandler 的 `ResponseStatusException` 一律回 404**：帳號重複（409）、沒權限（403）也變成 404。
   建議改成 `.status(ex.getStatusCode())`，訊息用 `ex.getReason()`（前端已經會把 `409 CONFLICT "..."` 清成乾淨的文字）。
5. **停用已停用的會員會回 500**：`IllegalStateException` 沒有被處理，掉到「系統發生錯誤」。建議在 GlobalExceptionHandler 加一個回 400 的處理。
6. **預約狀態大小寫（feature/booking-fangyu）**：Java 用 `"booked".equals(...)` 判斷，但測試資料存的是 `BOOKED`，
   所以測試資料裡的預約按「取消 / 改期」會回「此預約無法取消」。SQL 查詢不受影響（SQL Server 不分大小寫）。
   建議統一存小寫，或改成 `"booked".equalsIgnoreCase(...)`。
7. **`booking.note` 是 NOT NULL，但 `createBooking` 沒有給預設值**：前端已經固定送 `note: ""`，建議後端也補 `if (note == null) note = ""`。
8. **教練改期缺一支 API**：`PUT /coaches/{id}/reschedule` 需要 `newScheduleid`，但教練端沒有「查自己某天 open 時段」的 API，畫面沒辦法讓教練挑時段。
9. **教練看不到全館排課表**：`/admin/schedules/day` 只允許 admin。若教練端也要看，請開放 coach 或另開一支。
10. **`/booking/my` 建議回傳 `membercourseid`、`scheduleid`**：前端改期時目前用「課程名稱＋教練名稱」對回已購課程，有重名就可能對錯。
11. **`/api/user/**` 和 `/api/member/**` 沒有註冊到 LoginInterceptor**：之後會員端 API 放在 `/api/member` 開頭的話，記得加進 WebConfig。

## 打包上線

```bash
npm run build
```

產出在 `dist/`。可以把 `dist/` 的內容放進 Spring Boot 的 `src/main/resources/static/`，前後端同一個網址就不用設定 CORS。
這種做法要注意兩件事：後端要把 `/student/**`、`/trainer`、`/manage`、`/signin` 轉給 `index.html`（否則重新整理會 404），
而且 LoginInterceptor 要放行這幾個前端路徑和靜態檔。
分開部署的話，在 `.env.production` 填 `VITE_API_BASE_URL`，並在後端開 CORS（允許該網域、`allowCredentials=true`）。
