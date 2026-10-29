# POWER GYM Dashboard（學員端・教練端版面骨架）

React + TypeScript + Vite。只有版面，**沒有任何資料、沒有 API 串接、沒有登入**：
登入與權限由其他組員負責，API 留在後端（`GymProject` 的 `dashboard-only` 分支）。

## 啟動

```bash
npm install
npm run dev
```

打開 http://localhost:5173/
- 學員端：`/student`
- 教練端：`/trainer`

## 頁面

只有兩個首頁。側邊欄使用組員的 Sidebar，其他選單項目的頁面由組員製作：點了會到 `/student/{key}` 或 `/trainer/{key}`，還沒加入前會回到該端首頁。

| 網址 | 頁面 | 內容 |
|---|---|---|
| `/student` | 學員首頁 | 下一堂課、會員管理、InBody 分析、課程管理、出席紀錄 |
| `/trainer` | 教練首頁 | 日期選擇、當日統計、今日教學課表、全館教練排課表 |

## 專案結構

```
src/
├─ App.tsx                 路由
├─ components/
│  ├─ AppShell.tsx           版面：左邊放組員的 Sidebar，右邊放頁面（依網址決定學員端或教練端）
│  ├─ Sidebar.jsx / .css     組員的側邊欄（feature/frontend-fangyu），原檔照搬，不要修改
│  ├─ Sidebar.d.ts           讓 TypeScript 能使用 Sidebar.jsx 的型別宣告
│  ├─ ui.tsx                 Card、StatTile、PageHeader、StatusPill、ProgressBar
│  ├─ skeleton.tsx           預留區塊：Placeholder、EmptyTable、MetaList、MiniStats
│  └─ ScheduleGrid.tsx       排課狀態圖例
├─ pages/student/StudentHome.tsx  學員首頁
├─ pages/coach/TrainerPage.tsx    教練首頁
├─ utils/format.ts         日期、時間、數字格式化
└─ styles.css              全部樣式（顏色在最上面的 :root）
```

## 之後要接資料時

畫面上的「—」、「尚無資料」和虛線框（`Placeholder`）都是預留位置，
把它們換成從後端拿到的資料即可。後端可用的 API 見 `GymProject` 的 Controller。
