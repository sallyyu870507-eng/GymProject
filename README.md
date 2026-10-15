# POWER GYM 前端（React + Vite）

對接後端：tw.gym（Spring Boot，Session 登入）

## 執行
1. 啟動後端（預設 http://localhost:8080）
2. 在本資料夾：
   ```
   npm install
   npm run dev
   ```
3. 開啟 http://localhost:5173 ，用帳號密碼登入；系統依後端回傳的身分（member / coach / admin）自動進入對應畫面

開發時 `/api/*` 會由 vite.config.js 轉給 localhost:8080（同網域，不需要 CORS）。

## 結構
```
src/
  api/        http.js（統一請求：Cookie、錯誤處理）、gymApi.js（一支 API 一行）
  auth/       AuthContext（目前身分）、RequireRole（依身分擋頁面）
  components/ Layout（側邊欄 + 手機抽屜）、DataTable、DateNav、State、Badge
  hooks/      useAsync（載入中／錯誤／重新載入）
  pages/      member/ coach/ admin/ 各身分的頁面
  styles/     tokens.css（品牌色，深/淺色）、app.css
  App.jsx     路由與各身分的選單
```

## 對照後端 API
| 身分 | 前端頁面 | API |
|---|---|---|
| 會員 | 課程預約 | GET /members/courses、…/{id}/available-dates、…/{id}/schedules?date=、POST /booking |
| 會員 | 我的課程 | GET /members/courses |
| 教練 | 教學課表 | GET /coaches/dashboard?date=、GET /coaches/schedules?date= |
| 管理員 | 全館排課表 | GET /admin/schedules/coaches、GET /admin/schedules/day?date= |
| 登入 | 登入頁 | POST /auth/login（送 { account, password }，回傳 { role, name }）※ 後端需提供 |

## 常見修改
- 新增頁面：`pages/` 新增檔案 → `App.jsx` 加 link 與 Route
- 品牌色：`styles/tokens.css`
- 登入 API 的路徑或欄位和後端不同：只改 `src/api/gymApi.js` 的 `login`
- 前後端分開部署：`.env` 的 `VITE_API_BASE` 改成後端完整網址，後端開 CORS（allowCredentials），Cookie 設 SameSite=None; Secure
