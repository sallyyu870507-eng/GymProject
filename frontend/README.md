# GymProject 共同前端

React 19 + Vite 7，四位組員的會員管理、課程／教練、排課／預約、出席／續約關懷集中於本目錄。

Node.js 22.12 以上，先啟動既有 Spring Boot／資料庫，再執行：

```powershell
cd 'D:\iSpan course\GymProject\frontend'
npm ci
npm run dev
```

開啟 `http://localhost:5173`，使用團隊既有帳號登入。後端預設 `http://localhost:8080`；可複製 `.env.example` 為 `.env.local`，調整 `BACKEND_URL` 並重啟 Vite。

```powershell
npm run typecheck
npm run lint
npm test
npm run build
```

整合來源、路由、API 對應、樣式隔離及後端待確認事項見 [INTEGRATION.md](INTEGRATION.md)；實際驗證範圍見 [VALIDATION.md](VALIDATION.md)。`npm run preview` 與正式環境需要另設同源 API 反向代理及 SPA fallback，本次未部署。

`node_modules/`、`dist/`、本機環境檔、測試 fixture 與備份 `.local-safety/` 均被忽略。2026-10-22 的原 README／驗證紀錄已保存在本機 `.local-safety/before-integration/frontend/`。
