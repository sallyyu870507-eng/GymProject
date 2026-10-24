# 出席與續約後端團隊整合說明
> **本版本用途：後端交付說明。** 新分支 `integration/team-backend-20261025` 以 Main `a788b4eabc475003341de9b6bfddafb7d5d418f9` 為基準；原整合 Commit `389df34cf418c9edc021ca9aa79edffc6941d061` 只是後端程式與文件的來源，並非新分支的提交。
>
> - 此分支不納入 `frontend/**`、`docs/frontend-reference/**` 或前端素材，Main 原有 `static/**` 與 `webapp/**` 保持原樣。
> - 團隊資料庫交付僅包含完整建表檔 `database/02_create_tables_integrated.sql`。目前腳本固定 `USE [gymproject]`，會刪除該資料庫既有資料表及資料；執行前必須確認 `gymproject` 指向可清空的測試環境。組員測試資料由各自準備；`V5_sample_data(20261018).sql` 不隨交付。
> - 依交付者提供的隔離驗證結果，02 建表及 V5 匯入檢查已通過；此結果不代表其他組員的 API 或管理員購課、課程、會員／教練預約流程已驗證。本分支未重跑 SQL。
> - 本文件其餘整合分析記錄原整合版本的來源、修改與測試背景；涉及前端的驗證紀錄不代表 React 前端包含在本次交付。

## 新後端交付版本驗證（2026-10-25）

新交付分支以 Main `a788b4eabc475003341de9b6bfddafb7d5d418f9` 為基準，整合 Main 既有後端與出席、續約／關懷後端功能。原整合 Commit `389df34cf418c9edc021ca9aa79edffc6941d061` 僅作為程式來源；新分支尚未提交該版本，也不包含 React 前端。

### 已驗證

- 新 worktree 後端 Maven compile 成功，應用啟動成功。
- 使用原 React 前端連接新後端，依使用者回報完成出席列表與詳情、PRESENT 扣堂及重存不重扣、LEAVE 補堂及不重複補堂、訓練重點與 InBody 儲存／清除、關懷新增／修改／重新載入，以及續約建立新方案和重新載入確認。來源方案堂數保持不變。
- 02 建表及 V5 匯入的隔離測試依使用者回報已通過。V5 只作這次驗證使用，不納入團隊交付。

### 尚未驗證

- 管理員購課、課程新增／修改，以及其他組員的會員／教練預約 API 尚未實際驗證。
- 上述出席、關懷及續約手動結果不代表所有 Main 模組或所有 API 均已通過測試。

### 團隊資料庫交付

- 團隊僅交付正式完整建表檔 `database/02_create_tables_integrated.sql`。它包含 12 張表，目前固定 `USE [gymproject]`，會刪除該資料庫既有表及資料；執行前必須確認 `gymproject` 指向明確允許清空的測試環境。不得在保留資料的資料庫執行。
- `database/01_create_tables.sql` 保持 Main 原樣。01 與 02 是不同版本的完整建表腳本，擇一使用，不可依序執行。
- 團隊測試資料由各組員自行準備。V5、V4、V6 及其他 migration 不隨此次交付。
## 原整合版本紀錄

## 文件範圍與版本

- ours：`4a7342c50d268f92fd1593458bae082e98773423`（`feature/attendance-renewal`）。
- theirs：`a788b4eabc475003341de9b6bfddafb7d5d418f9`（`origin/main`）。
- 原始整合分支：`integration/attendance-renewal-main-20261024`（歷史紀錄，不是本文件所述的新後端交付分支）。
- 本文件依兩個提交、目前索引與工作目錄整理。來源標示只說明程式版本來源，不代表個人作者。
- Main 原樣帶入的檔案以模組摘要分類，不逐行重述。部分 Main 檔案經必要契約調整，另列於下方。

## 模組整合摘要

### 共用 Entity 與資料映射

**來源：雙方都有；共用模型依 Main 呼叫端契約整合，保留出席與續約需要的欄位。**

- `src/main/java/tw/gymproject/entity/Membercourse.java`：唯一 Entity 類名與路徑採 Main 的 `Membercourse`；將 ours 的出席、續約欄位及關聯併入。索引只保留這一路徑，沒有並存 `MemberCourse.java`。此命名處理大小寫路徑碰撞，避免同一資料表被兩個 Entity 映射。
- `src/main/java/tw/gymproject/entity/Member.java`、`Booking.java`、`ClassSchedule.java`、`Course.java`、`Coach.java`、`CoachCourse.java`、`Renewal.java`、`Attendance.java`、`FollowUp.java`、`InBodyRecord.java`、`Useraccount.java`：兩方模型與呼叫端需要協調；保留 `Member.avatarurl`、續約關聯和兩邊服務需要的 FK／關聯。
- `Booking` 的 `membercourseid`、`scheduleid` 是可寫欄位；`membercourse`、`schedule` 關聯設為唯讀映射。建立預約讀取並儲存純量 ID，會員與教練改期都設定 `scheduleid`。未發現只設定唯讀關聯的 Booking 寫入流程。現有 ClassSchedule 端只有讀取／DTO 組裝，沒有找到課表 Entity 建立或更新流程。
- 影響：管理員購課、會員預約、出席查詢／更新、續約及預約查詢共用同一模型。資料庫映射以程式檢查與目前資料庫回報為依據；建表 SQL 不視為實際資料庫結構。

### 價格型別與課程契約

**來源：雙方都有 Course；型別採 Main 的 BigDecimal 契約，並配合本機資料庫遷移。**

- `src/main/java/tw/gymproject/entity/Course.java`、`dto/CourseCreateRequest.java`、`dto/CourseUpdateRequest.java`、`service/CourseService.java`、`service/AdminPurchaseCourse.java`：課程價格使用 `BigDecimal`，保留 Main 的非負、最多 8 位整數與 2 位小數規則。
- `CourseCreateRequest.description` 與 `CourseUpdateRequest.description` 保留最多 500 字限制，但未要求必填。整合時額外加入的兩個 `@NotNull` 已移除，因 Main 原始 DTO 未規定必填；資料庫 NOT NULL 本身不足以推導空字串或 null 的 API 驗證契約。
- 本機 `gymproject.dbo.course.price` 已依使用者回報改為 `decimal(10,2) NOT NULL`；`CK_course_values` 以相同規則重建，啟用且受信任，五筆價格資料保留。此為本機資料庫現況，不是本次執行 SQL 的結果。
- 遷移腳本另存於 `database/migrations/V6_course_price_decimal_10_2.sql`，標註前提及本機已執行；本次只保存，沒有執行 SQL。

### Repository 整併

**來源：雙方都有；套件／查詢整理配合 Main 模組和 ours 出席續約服務。**

- `src/main/java/tw/gymproject/dao/AccountRepository.java`、`dao/CoachRepository.java` 移除；共用版本在 `repository/AccountRepository.java`、`repository/CoachRepository.java`。
- `dao/MemberRepository.java` 移至 `repository/MemberRepository.java`。
- `repository/MemberCourseRepo.java`、`repository/RenewalRepo.java`、`repository/AttendanceRepo.java` 整合續約、出席與 Main 呼叫端所需查詢。
- `repository/BookingRepository.java`、`ClassScheduleRepository.java`、`CourseRepo.java`、`CoachCourseRepo.java`、`AdminMemberCourseRepo.java` 為 Main 共用模組新增的 Repository，供預約、課程及管理員購課使用。
- 影響：Repository 方法、Entity 屬性名稱及 JPQL 必須與統一後模型一致；後端 compile 已成功，但未因此證明每個查詢在真實資料庫均已執行。

### 登入 Session 與權限

**來源：雙方都有 AccountService／登入流程；以 Main Session 回傳欄位配合 ours 教練 Session 取值。**

- `service/AccountService.java`、`dto/LoginResultDTO.java`、`controller/LoginController.java`、`controller/ApiUserController.java`、`service/CoachSessionService.java`、`interceptor/LoginInterceptor.java`、`config/WebConfig.java`。
- Main 登入結果提供 `accountid`、`username`、`role`，並依角色設定 `memberid` 或 `coachid`；`CoachSessionService` 保留以 `accountid` 查詢教練的既有流程。`admin` 在 ours、Main 與整合版均有明確成功分支；整合沒有新增管理員登入支援。
- 保留 `/api/coach/attendance`、`/api/coach/renewal` 與 `/api/coach/**` 教練權限保護。沒有為通過編譯或測試而放寬角色、登入或資料所屬檢查。
- 影響：登入後頁面及教練／會員／管理員端點依 Session 角色與 ID 運作。Main 中尚未實際驗證的購課及預約流程仍需另測。

### 出席、預約及續約服務

**來源：出席與續約服務來自 ours 並按 Main 共用契約調整；預約服務主要由 Main 帶入。**

- ours 功能檔案：`service/AttendanceService.java`、`AttendanceSummaryService.java`、`FollowUpCreateService.java`、`FollowUpQueryService.java`、`FollowUpUpdateService.java`、`InBodyQueryService.java`、`RenewalCreateService.java`、`RenewalOptionsService.java`、`RenewalOverviewService.java`、`RenewalWorkbenchService.java` 及 `controller/RenewalController.java`、`AttendanceController.java`。
- 配合 Membercourse 唯一 Entity、欄位／關聯名稱及 Repository 契約調整引用；續約仍建立新 `Membercourse` 再建立 Renewal 關聯，不增加來源方案堂數。FollowUp 的「同意續約」不取代 Renewal 關聯判定。
- Main 共用預約檔案：`controller/BookingController.java`、`BookingCoachController.java`、`service/BookingService.java`、`BookingCoachService.java`、`repository/BookingRepository.java`、`ClassScheduleRepository.java`。預約改期以 FK 純量 `scheduleid` 更新。
- 使用者已手動通過出席查詢／扣補堂／InBody、關懷新增與修改、續約建立新方案流程。預約各端及管理員購課尚未實際驗證。

### 例外處理、啟動與設定

**來源：雙方都有設定及例外處理；整合兩邊錯誤契約，保留本機私有設定。**

- `exception/GlobalExceptionHandler.java`、`exception/DuplicateUsernameException.java`、`config/WebConfig.java`、`interceptor/LoginInterceptor.java`、`GymApplication.java`、`pom.xml`、`src/main/resources/application.properties`、`.gitignore`。
- 保留原始 HTTP 狀態處理需求（包含 400、401、403、404、409），`ResponseStatusException` 不應被一律轉成 404；靜態資源未找到應是 404，未預期錯誤記錄堆疊但不向回應洩漏內部資訊。
- 共用設定維持 `ddl-auto=validate`；ignored 的 `application-local.properties` 不納入文件或輸出內容。沒有升級依賴，也沒有寫入機密。
- Main 原始帶入的 `src/main/resources/META-INF/persistence.xml` 改名 `.bak`。目前整合設定使用 Spring Boot/JPA；改名用途沒有足夠證據可確認，應由維護者確認是否仍有外部工具或工作流程依賴該檔。

### Main 原樣帶入的檔案分類

以下多為 Main 新增或帶入，未逐行改寫：

- 管理員、課表及課程端點：`controller/AdminController.java`、`AdminPurchaseCourseController.java`、`AdminScheduleController.java`、`CourseController.java`、`service/AdminScheduleService.java`、`AdminPurchaseCourse.java`、`CourseService.java`。
- 教練及會員管理／瀏覽：`controller/CoachCourseController.java`、`CoachManagementController.java`、`CoachMemberController.java`、`StudentCoachController.java`、`StudentCourseController.java`，以及相對應 `service`、`dto`、`repository` 類別。
- 預約／改期：前述 Booking Controllers、Services、Repositories 及其 DTO。
- 管理員靜態頁：`src/main/resources/static/admin.html`；`coach.html`、`login.html`、`member.html` 則屬兩邊已有頁面的整合版本。
- SQL 文件：`database/01_create_tables.sql`。該檔是設計文件，不代表本機資料庫實際結構，也未在本次執行。

## 驗證狀態與限制

### 已完成／已驗證

- Git 索引未列出未解衝突項目；`src`、`frontend` 搜尋未找到標準衝突標記。
- 索引與工作目錄只有 `src/main/java/tw/gymproject/entity/Membercourse.java`，沒有大小寫重複 Entity。
- 使用者回報前端 build、後端 compile、GymApplication 啟動成功；本次沒有重跑建置。
- 使用者手動通過出席查詢／扣補堂／InBody、關懷新增與修改、續約建立新方案。
- 使用者回報本機 `course.price` 已遷移，5 筆價格保留，`CK_course_values` 啟用且受信任。
- 使用者回報 `renewal.newmembercourseid` 已有啟用、受信任外鍵與唯一索引，孤兒筆數為 0；不需新增或修改該外鍵。

### 未完成／尚未驗證

- 管理員購課、課程新增／修改、會員預約、教練預約／改期缺少可用測試畫面，尚未實際驗證。不得將其標為通過。
- 未執行資料庫整合測試，也未實際驗證全部 JPQL、Repository 查詢與每個 API 權限情境。
- `persistence.xml.bak` 的保留／移除用途待維護者確認。
- 使用者回報的本機 DB 遷移結果未由本次連線獨立查證。

### 已知空白問題

索引差異中的部分 trailing whitespace／混合縮排來自 Main 原始帶入內容（例如 Main 新增的管理員／預約程式與建表 SQL）。本次不做全面格式清理；空白問題不應與功能衝突混為一談。

## 接手資訊

- 原始整合分支：`integration/attendance-renewal-main-20261024`（歷史紀錄，不是本文件所述的新後端交付分支）。
- ours：`4a7342c50d268f92fd1593458bae082e98773423`。
- theirs／`MERGE_HEAD`：`a788b4eabc475003341de9b6bfddafb7d5d418f9`。
- Merge 已於 `389df34cf418c9edc021ca9aa79edffc6941d061` 完成；之後已推送整合分支。資料庫文件更新不改變該提交紀錄。
- 已驗證：沒有未解索引衝突或標準衝突標記；只有單一 `Membercourse.java`；使用者回報前端 build、後端 compile、應用啟動與列明的手動流程成功；本機價格遷移與 Renewal FK 狀態依使用者查詢結果記錄。
- 未驗證：管理員購課、課程新增／修改、會員／教練預約與改期、所有資料庫查詢的執行期相容性；`persistence.xml.bak` 用途仍待確認。
- 下一步：先由維護者確認 `persistence.xml.bak` 是否仍有用途；補做管理員課程／購課及會員、教練預約流程驗證；確認部署環境選擇正確的資料庫腳本流程。

## 共用資料庫腳本與 Renewal 整合（2026-10-25）

### 完整建表檔版本

- `database/01_create_tables.sql`：組員原始共用版本，工作目錄內容與整合 Commit `389df34cf418c9edc021ca9aa79edffc6941d061` 中的檔案完全一致，未套用本次 Renewal 整合。
- `database/02_create_tables_integrated.sql`：以組員原始 01 為基礎的完整整合版，保留 `course.price decimal(10,2) NOT NULL`，並合入 V4 的完整 Renewal 結構。包含 12 張表，可獨立執行，不需先執行 01。
- 02 的 Renewal 欄位為 `membercourseid`、`newmembercourseid`、`renewaldate`、`addedsessions`、`amount`、`paymentmethod`、`note`；日期、堂數、金額、付款方式為 `NOT NULL`。包含來源及新方案外鍵、新方案唯一約束、不同方案 CHECK、堂數／金額 CHECK。
- 01 與 02 是不同版本的完整建表檔，選一份執行，不能依序執行。兩份都是破壞性腳本：會刪除 gymproject 的使用者資料表及資料，只供新建或明確允許重建的測試環境。
- 靜態比對 12 張 CREATE TABLE 欄位：02 與 V4 只在 Course 價格型別有預期差異（02 為 decimal、V4 為 int），Renewal 欄位一致。約束名稱集合亦與 V4 一致；02 保留原 01 其餘既有結構與約束。
- 對照 Entity：`entity/Renewal.java` 有來源與新方案關聯，新方案 OneToOne／唯一；欄位名稱及 Java 型別相符。Entity 的日期、堂數、金額、付款方式 nullable 註記未明確設為 false，而 02/V4 為 NOT NULL；`RenewalCreateService` 建立時會設定這四欄。此 nullability 差異仍需於 Hibernate／實際環境確認，本次不修改 Java。

### 測試資料與歷史遷移

- `database/migrations/V5_sample_data(20261018).sql`：只供本次隔離驗證使用，不納入團隊交付；團隊測試資料由各組員自行準備。
- V4、V5、V6 僅為原整合過程的歷史參考；本後端交付分支不帶入這些 migrations。V5 僅供本次隔離驗證，不作團隊測試資料。
- V6 是價格仍為 `int NOT NULL` 的既有資料庫遷移。使用 02 新建的環境已是 `decimal(10,2)`，不需執行 V6。使用者已確認目前本機資料庫完成價格遷移且測試正常，不需重建。
- 本次新增的未提交 V7 不列入交付，已在確認仍為本次建立的未追蹤檔案後移除；本次不開發續約增量遷移。舊共用 Renewal 資料若沒有可靠的新方案逐筆對應，需先由維護者決定資料遷移方案，不能猜 ID 或建立假方案。
- 隔離建表與 V5 匯入檢查依交付者提供的結果已通過；本次建立後端交付分支時未重跑 SQL。這不代表其他組員 API 已驗證。

#
## 團隊使用方式

1. 只在新建或明確允許清空的測試資料庫執行 `database/02_create_tables_integrated.sql`；此檔是完整建表腳本，會刪表並清除資料。不要把 `01` 與 `02` 依序執行。
2. 團隊測試資料由各組員自行準備；V5 是本次隔離驗證用腳本，不隨後端交付。
3. 本次提供的隔離驗證結果僅涵蓋 02 建表與 V5 匯入檢查；其他組員 API 仍須由各自流程驗證。
4. 保留資料的既有資料庫不得執行 02；先唯讀核對，再另行規劃經審閱的增量遷移。此交付不含 V4、V5、V6 或其他 migrations。