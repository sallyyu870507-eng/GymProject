# 團隊展示資料操作說明

## 腳本用途與資料安全

`03_team_reset_and_seed.sql` 是完整的 **RESET + 建表 + 假資料 + 腳本內驗證** 腳本，不需要先執行 `01_create_tables.sql`。它只允許目標資料庫 `gymproject_seed_verify_20261030`。

**執行會刪除這個目標測試資料庫內 12 張既有資料表及全部資料，並清除既有操作成果，再重建與匯入展示資料。**不要在含有要保留資料的資料庫執行；若要保留目前測試操作，先停止並另行備份資料。不要只執行選取片段，請整份執行腳本。

腳本若目標資料庫不存在，會建立指定的隔離測試庫；若已存在，會在目標庫內重建表與資料。它不應操作正式 `gymproject`。執行前請再次確認 SSMS 的腳本內容、`TargetDatabase` 訊息與資料庫名稱。

## 執行步驟

1. 停止後端服務，避免應用程式同時連線或寫入測試庫。
2. 在 SSMS 開啟最新版本的 `database/03_team_reset_and_seed.sql`，確認檔頭及目標名稱是 `gymproject_seed_verify_20261030`。
3. 不反白局部 SQL，執行整份腳本。等待完成，確認 Messages／結果顯示目標資料庫、revision、SeedAsOf 與「RESET及匯入成功」；若有錯誤，腳本交易會回滾資料表與資料重建部分；若這是首次建立的資料庫，空資料庫本身仍可能保留。請先保留錯誤訊息，不要略過驗證後繼續。
4. 將自己電腦的後端連線設定指向 `gymproject_seed_verify_20261030`，再啟動後端。
5. 手動操作測試後若重跑此腳本，該測試庫內新增、修改、取消等成果都會被清除。

## 每台電腦自己的 SQL Server 與本機設定

後端共用設定使用 `DB_URL`、`DB_USERNAME`、`DB_PASSWORD`，並要求 Hibernate `ddl-auto=validate`。請在自己電腦的 IntelliJ Run Configuration 或私有環境變數中設定，將 JDBC URL 的 `databaseName` 指向 `gymproject_seed_verify_20261030`。範例中的主機、登入名稱及密碼必須由各組員依自己的環境填入；不要把真實密碼寫進 Git、共用文件或提交內容。

若使用被 `.gitignore` 排除的 `src/main/resources/application-local.properties`，請只在本機建立並於 IntelliJ Run Configuration 啟用 `local` profile（例如 Active profiles 填 `local`）；設定內容仍應使用自己的 SQL Server 與權限。也可直接在 Run Configuration 設定所需環境變數。不要修改共用 `application.properties` 來放個人連線資訊。

SQL Server 的伺服器登入、目標資料庫使用者對應及權限都是各電腦／各 SQL Server 執行個體自己的設定，Git Pull 不會替你建立或設定它們。請依團隊／管理者提供的方式取得該隔離庫所需權限，遵循最小權限原則；本指南不會建立伺服器登入，也不要求授予系統管理員權限。

## 本機展示測試帳號

以下帳號共用僅供本機展示的測試密碼 `GymDemo2026!`，不要用於正式環境，也不要與真實帳號共用：

- 管理員：`admin_demo`
- 教練：`coach_amy`、`coach_ben`、`coach_chris`、`coach_david`、`coach_eric`
- 會員：`member001` 至 `member035`

人物與聯絡資料均為虛構展示資料。會員照片放在 `frontend/public/avatars`；相關照片檔納入 Git 並推送後，其他組員 Pull 即可取得。照片能否顯示仍取決於前端版本與檔案是否已提交／推送。

## 此版本日期範圍與資料特性

- 允許初始化的台北日期：**2026-10-30 至 2026-11-13（含首尾）**。腳本只在此固定日期窗執行，其他日期會停止。
- AMY 的每日預約展示：**2026-10-01 至 2026-11-13（含首尾）**，每天至少四位不同會員有非取消預約。
- 五位教練的班表：**2026-10-30 至 2026-12-13（含首尾）**。11/14 至 12/13 延伸的是可預約開放時段，沒有預先替每個空位建立會員預約；可用於展示新增預約、取消、改期。
- 11/13 當天仍會產生可操作的待點名預約；未開始的課程不預填出席結果或 InBody。具體狀態以腳本的 `SeedAsOf(Taipei)` 與上課開始時間判斷。
- 日期是固定的展示資料，不會隨日曆自動滾動；超過允許初始化日後，腳本會停止。若要延長日期窗，需另行審閱更新腳本，不要自行刪除日期防呆。
- 時區依賴 SQL Server 可識別 `Taipei Standard Time`，後端 JVM／SQL Server 時鐘是否一致需在各自環境確認；本文件不代表已做跨環境時區驗證。
- 腳本內驗證只核對資料與約束，不等於前後端 API 或各組員電腦上的 SQL Server 已通過實際測試。
