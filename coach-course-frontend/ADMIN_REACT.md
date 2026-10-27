# 管理員教練／課程 React 頁面

## Vite 開發環境管理員測試入口

- 開關位置：`src/adminTestMode.js`，條件為 `import.meta.env.DEV` 且網址參數 `adminTest=1`，預設關閉。
- 執行 `npm.cmd run dev`，開啟 `http://localhost:5173/?adminTest=1`（若 Vite 使用其他埠，依終端網址加上 `?adminTest=1`）。預設開啟課程管理，使用既有管理員 Sidebar 切換教練管理。
- 啟用時 App 與 Sidebar 都使用測試角色，顯示「管理員測試模式」，不呼叫 `/api/user`，不建立或修改正式登入身分。
- 教練、課程及授課關聯仍呼叫真實後端；儲存會改動真實資料。業務 API 若回傳 401／403，畫面顯示端點、狀態碼及錯誤訊息，前端不繞過後端權限。
- 關閉方式：按頁面「關閉測試模式」，或移除網址的 `adminTest=1` 後重新載入，即恢復原本登入流程。
- `npm.cmd run build` 的正式產物及 `npm.cmd run preview` 不啟用此入口，即使網址包含 `adminTest=1` 亦同。

## 開啟方式

1. 啟動既有後端（`http://localhost:8080`），使用既有 `/login` 流程登入管理員。
2. 在本目錄執行 `npm.cmd run dev`，開啟終端顯示的 Vite 網址（預設 `http://localhost:5173`）。登入與 Vite 請使用相同主機名稱 `localhost`。
3. `/api/user` 回傳 `role: "admin"` 時，既有 Sidebar 的「教練管理／課程管理」會開啟管理員元件；`member` 使用原學員元件。未取得身分時顯示讀取或登入錯誤。

## 本次檔案

- 新增 `src/components/AdminCoaches.jsx`、`AdminCourses.jsx`：兩個管理員入口。
- 新增 `src/components/AdminManagement.jsx`、`AdminManagement.css`：列表、搜尋、關聯展開、表單、狀態切換及獨立樣式。
- 新增 `src/components/adminApi.js`：API、後端錯誤處理、完整列表與關聯讀取、保留其他課程的關聯更新。
- 修改 `src/App.jsx`、`src/components/Sidebar.jsx`：共用 Sidebar 取得的登入身分，依角色顯示頁面，保留登出流程與導向。
- 新增 `tests/adminApi.test.mjs`，並在 `package.json` 新增 `test:admin` 指令。

樣式依原本 Bootstrap 表格、按鈕與 Modal 外觀以管理員前綴隔離；現有 React 專案未引入 Bootstrap，未額外載入會影響學員頁面的全域 Bootstrap CSS 或 JS。視窗使用原生 dialog，由 React 控制，卸載時還原捲動與焦點。原 HTML／JS、後端與學員元件均保留。

## API 與限制

- 教練／課程基本資料使用既有 POST／PUT，之後視需要 PATCH 狀態，最後 PUT 教練的完整課程關聯。
- 課程頁逐位重讀教練當下課程，只增刪這次管理的課程，保留其他課程。
- 基本資料儲存成功後立刻保留回傳 ID，後續設定失敗會顯示部分完成訊息，保留表單供 PUT 重試。
- 新課程預設上架。現有 DTO 沒有時長欄位，後端新增固定 60 分鐘，因此表單只顯示時長、不提供修改。
- 前端角色分流僅控制顯示，不提供後端授權。未修改任何既有後端安全設定。

## 驗證紀錄

2026-10-27：

- `npm.cmd run lint`、`npm.cmd run build` 通過。
- `npm.cmd run test:admin`：5 項通過（使用模擬 HTTP 回應，驗證關聯保留／移除、部分失敗、實際關聯來源、回傳格式及登入錯誤）。
- 對本機後端執行唯讀檢查：`GET /api/coaches`、`GET /api/courses`、全部 5 位教練的 `/api/coaches/{id}/courses` 均為 200；成功讀取 5 位教練、5 門課程、10 筆關聯，數量僅為當次資料，程式沒有硬編碼。
- `GET /api/student/coaches`、`GET /api/student/courses` 均為 200，回傳陣列。
- 目前工具端沒有登入工作階段：`GET /api/user` 為 401。未執行真實新增、編輯、狀態或關聯寫入，也未執行瀏覽器登入、搜尋、展開收合、Modal、Sidebar 切換、登出及 RWD 操作測試；這些仍需以既有管理員／學員登入實機驗證。
- 未新增後端測試資料，未修改資料庫、API、安全設定與原管理員 HTML／JS。
