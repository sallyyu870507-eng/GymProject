# 出席與續約功能整合 Main 說明

## 文件範圍與版本

- ours：`4a7342c50d268f92fd1593458bae082e98773423`（`feature/attendance-renewal`）。
- theirs：`a788b4eabc475003341de9b6bfddafb7d5d418f9`（`origin/main`）。
- 目前分支：`integration/attendance-renewal-main-20261024`。
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

- 目前分支：`integration/attendance-renewal-main-20261024`。
- ours：`4a7342c50d268f92fd1593458bae082e98773423`。
- theirs／`MERGE_HEAD`：`a788b4eabc475003341de9b6bfddafb7d5d418f9`。
- Merge 尚未提交；目前整合索引保留在 Merge 中。新增的本文件及遷移 SQL 不暫存。
- 已驗證：沒有未解索引衝突或標準衝突標記；只有單一 `Membercourse.java`；使用者回報前端 build、後端 compile、應用啟動與列明的手動流程成功；本機價格遷移與 Renewal FK 狀態依使用者查詢結果記錄。
- 未驗證：管理員購課、課程新增／修改、會員／教練預約與改期、所有資料庫查詢的執行期相容性；`persistence.xml.bak` 用途仍待確認。
- 下一步：先由維護者確認 `persistence.xml.bak` 是否仍有用途；補做管理員課程／購課及會員、教練預約流程驗證；確認資料庫遷移環境與部署流程；檢閱所有暫存差異後再決定是否建立 Merge Commit。
