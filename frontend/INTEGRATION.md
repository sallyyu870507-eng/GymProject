# 前端整合說明

2026-10-28（Asia/Taipei）。成果位於 `integration/frontend-chiaying` 的 `frontend/`；只選取前端內容，未整支合併來源分支，未部署或建立 PR。依使用者後續指示，以「初次前端整合」提交至此分支。

## 來源與保留功能

| 來源快照 | 整合位置 | 功能 |
| --- | --- | --- |
| Chiaying `8a025c5` | `src/MemberPage.jsx`、`src/api.js` | Session 登入、管理員會員管理／購課、教練學員清單與編輯 |
| Iris `3a535a6` | `src/features/catalog/`、`public/images/` | 課程與教練瀏覽、詳細視窗、關聯介紹、管理員新增／編輯／狀態與授課關聯 |
| team `5c96c54` | `src/pages/`、`src/components/attendance/`、`src/components/renewal/`、`src/services/`、`src/types/`、`public/avatars/` | 出席、InBody、續約工作台／詳情、關懷新增／編輯、辦理續約 |
| Fangyu `041c86a` | `src/features/booking/`、共用側欄及 logo | 全館排課、教練課表與取消、會員預約／取消／改期 |

四份來源沒有完整互相包含；重複的 App、入口、Sidebar 與 Vite 範例版型只採一套。未使用的範例 hero/react/vite 圖示、Header/Layout 及測試身分切換入口未加入正式入口；功能頁與實際使用資源均保留。

## 共用入口與路由

`src/main.jsx` 使用 React Router data router，`src/App.jsx` 集中取得 `/api/user`、提供版型、角色導覽及 Outlet context。後端登入的 `/admin`、`/coach`、`/member` 重新導向由 SPA 接手。路由可直接開啟或重新整理。

| 身分 | 功能路徑 |
| --- | --- |
| 管理員 | `/members`、`/coaches`、`/courses`、`/schedule` |
| 教練 | `/`、`/students`、`/schedule`、`/attendance`、`/renewal` |
| 會員 | `/`、`/coaches`、`/courses`、`/my-bookings`、`/book-course` |
| 教練續約子頁 | `/renewal/:memberCourseId`、`/renewal/:memberCourseId/followups/new`、`/renewal/:memberCourseId/followups/:followupId/edit`、`/renewal/:memberCourseId/renewals/new` |

前端身分限制只控制畫面，真正授權仍由後端負責。未知路徑顯示返回首頁。續約表單保留未儲存提示、送出鎖定及原有冪等請求邏輯；側欄、瀏覽器返回與重新整理也納入離開保護。

## 衝突處理

- **側欄**：`Sidebar.css` 與 logo 直接採 Fangyu 來源；`Sidebar.jsx` 沿用其角色選單、結構與樣式類別，改由 App 注入登入者及路由，移除重複查詢和硬編碼後端位址。補窄螢幕選單、Escape 關閉與捲動保護。原根目錄未追蹤的 `src/components/`、`src/assets/` 保持原狀。
- **樣式**：會員、課程、預約各頁、出席／續約使用 CSS `@scope` 隔離，`:root` 變數改放在各功能 scope，避免全域表格、按鈕及標題互相污染。共同骨架在 `integration.css`。需支援 CSS `@scope` 的現代瀏覽器；較舊瀏覽器尚未驗證。
- **相依套件**：沿用目標分支 Vite 7／React 19 與 npm，加入 `react-router`、`react-calendar`、TypeScript 及 ESLint 所需套件，更新單一 `package-lock.json`；不另開三套專案或混用鎖定檔。JS 保留原貌，TS 功能保留 TS。
- **登入**：`sessionFetch.js` 統一 Session Cookie、401 與舊預約 API 導回登入頁的處理；初次未登入不顯示「登入過期」。登出走同源 `/logout`。沒有加入測試身分捷徑或帳密。
- **API**：預約功能移除 `http://localhost:8080`，開發代理共同使用 `BACKEND_URL`。`/coaches` 是前端教練頁，僅 `/coaches/dashboard`、`/coaches/schedules` 及數字 ID 操作轉送後端；登入 HTML GET 留在 React，表單 POST 才轉送 Spring。

Iris 最新來源使用較新的 API 命名，本機 Controller 仍使用舊命名，因此在前端做以下對應，沒有更動 Java：

| Iris 來源 | 本機共同前端使用 |
| --- | --- |
| `/api/admin/coaches` | `/api/coaches` |
| `/api/admin/courses` | `/api/courses` |
| `/api/relation/coaches/{id}/courses` | `/api/coaches/{id}/courses` |
| `/api/member/student/...` | `/api/student/...` |

原會員功能實際已使用 `/api/coach/members`，沿用；其餘出席、續約及預約路徑對照現有 Controller 保留。

## 啟動與檢查

Node.js 22.12 以上，先依團隊方式啟動 Spring Boot／資料庫：

```powershell
cd 'D:\iSpan course\GymProject\frontend'
npm ci
npm run dev
```

開啟 `http://localhost:5173`。後端預設 `http://localhost:8080`；其他位置可將 `.env.example` 複製為 `.env.local`，調整 `BACKEND_URL` 並重啟 Vite。固定使用 localhost，以免 Session Cookie 跨主機名稱失效。

```powershell
npm run typecheck
npm run lint
npm test
npm run build
```

`build` 含 TS 型別檢查，JS 由 Vite 解析；ESLint 執行 JS／TS 的基本正確性規則。原續約程式刻意對齊 Java whitespace 的三個控制字元正規表示式，以單行註解保留，不改變驗證行為。

`dist/` 為本機建置結果，不會自動寫入 Spring static。部署／preview 需要另外提供同源 API 反向代理及 SPA fallback；本次未部署。建置有單一 JS chunk 超過 500 kB 的效能提醒，未阻擋產出。

## 驗證與團隊接續

詳細結果見 `VALIDATION.md`。本機唯讀 fixture 僅用於瀏覽器驗證，存於被忽略的 `.local-safety/`，不會隨專案提交，也不會轉送請求或寫入真實資料。

需要團隊確認：

1. 提供三種角色的測試帳號與可寫入的測試資料，完成真實登入、預約／改期／取消、會員及課程管理、出席／InBody、續約等端到端驗收；本次沒有執行真實資料寫入。
2. **本機後端路徑與權限註冊不一致**：Controller 仍用 `/api/coaches`、`/api/courses`、`/api/student`，但目前 `WebConfig` 未將這些路徑註冊給 `LoginInterceptor`；`LoginInterceptor` 的 `/api/coach` 前綴也會涵蓋 `/api/coaches`，若只補註冊可能錯擋管理員／會員。請後端統一採舊路徑或 Iris 新命名，並一併核對角色權限。前端對應目前 Controller 不代表後端授權已通過驗證。
3. 正式環境的主機、Session 設定、SPA fallback 與反向代理由團隊決定。

## 現有工作保護

整合前的狀態、差異、前端原檔與既有未追蹤檔案已留在被忽略的 `.local-safety/before-integration/` 與同層紀錄。後端、IDE 設定及既有 static 建置檔均未修改。請檢視差異後只暫存本次 `frontend/` 所需檔案，避免將原本未提交的後端／IDE 修改一起提交。
