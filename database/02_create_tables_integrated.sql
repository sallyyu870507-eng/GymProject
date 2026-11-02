/* 整合版完整建表腳本：以組員原始 01 為基礎，合入 V4 的完整 Renewal 結構。
   本檔包含完整 12 張表，可獨立執行，不需先執行 01。
   破壞性：本檔會刪除 gymproject 中所有使用者資料表、外鍵及既有資料。
   僅供新建或已明確允許重建的測試環境；不要用於保留資料的現有環境。
   01 與 02 是不同版本的完整建表檔，擇一使用，不是依序執行。
   需要測試資料時，確認本檔成功後才可另行執行 V5；V5 本身也會清空資料並重設 IDENTITY。
   僅完成靜態核對，尚未在 SQL Server 實際執行驗證。 */
USE [master];
GO
IF DB_ID(N'gymproject') IS NULL
    EXEC(N'CREATE DATABASE [gymproject]');
GO
USE [gymproject];
GO
SET XACT_ABORT ON;
SET NOCOUNT ON;
GO
BEGIN TRY
    BEGIN TRANSACTION;
    -- DEBUG原因：先移除所有 schema 的外鍵，再逐表刪除，避免外鍵相依阻擋。
    DECLARE @drop nvarchar(max) = N'';
    SELECT @drop = @drop + N'ALTER TABLE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
        + N' DROP CONSTRAINT ' + QUOTENAME(f.name) + N';' + NCHAR(10)
    FROM sys.foreign_keys f
    JOIN sys.tables t ON t.object_id = f.parent_object_id
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0;
    IF @drop <> N'' EXEC sys.sp_executesql @drop;
    SET @drop = N'';
    SELECT @drop = @drop + N'DROP TABLE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N';' + NCHAR(10)
    FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0;
    IF @drop <> N'' EXEC sys.sp_executesql @drop;
    EXEC sys.sp_executesql N'SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[attendance](
	[attendanceid] [int] IDENTITY(1,1) NOT NULL,
    [updatetime] [datetime] NULL,
	[bookingid] [int] NOT NULL,
	[checkintime] [datetime] NULL,
	[attendancestatus] [nvarchar](50) NOT NULL,
	[workoutfocus] [nvarchar](50) NULL,
	[note] [nvarchar](100) NULL,
 CONSTRAINT [PK_attendance] PRIMARY KEY CLUSTERED
(
	[attendanceid] ASC
)
)

SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[booking](
	[bookingid] [int] IDENTITY(1,1) NOT NULL,
	[membercourseid] [int] NOT NULL,
	[scheduleid] [int] NOT NULL,
	[bookingtime] [datetime] NOT NULL,
	[bookingstatus] [nvarchar](20) NOT NULL,
	[note] [nvarchar](100) NOT NULL,
	[updatetime] [datetime] NOT NULL,
 CONSTRAINT [PK_booking] PRIMARY KEY CLUSTERED
(
	[bookingid] ASC
)
)

SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[classschedule](
	[scheduleid] [int] IDENTITY(1,1) NOT NULL,
	[coachid] [int] NOT NULL,
	[courseid] [int] NOT NULL,
	[classdate] [date] NOT NULL,
	[starttime] [time](0) NOT NULL,
	[endtime] [time](0) NOT NULL,
	[classroom] [nvarchar](50) NOT NULL,
	[status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_classschedule] PRIMARY KEY CLUSTERED
(
	[scheduleid] ASC
)
)

SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[coach](
	[coachid] [int] IDENTITY(1,1) NOT NULL,
	[accountid] [int] NOT NULL,
	[coachno] [nvarchar](20) NOT NULL,
	[name] [nvarchar](50) NOT NULL,
	[gender] [nvarchar](10) NOT NULL,
	[phone] [nvarchar](50) NOT NULL,
	[email] [nvarchar](100) NOT NULL,
	[specialty] [nvarchar](100) NOT NULL,
	[status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_coach] PRIMARY KEY CLUSTERED
(
	[coachid] ASC
)
)

SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[coachcourse](
	[coachid] [int] NOT NULL,
	[courseid] [int] NOT NULL,
 CONSTRAINT [PK_coachcourse] PRIMARY KEY CLUSTERED
(
	[coachid] ASC,
	[courseid] ASC
)
)

SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[course](
	[courseid] [int] IDENTITY(1,1) NOT NULL,
	[coursename] [nvarchar](100) NOT NULL,
	[coursetype] [nvarchar](50) NOT NULL,
	[description] [nvarchar](max) NOT NULL,
	[durationmin] [int] NOT NULL,
	[price] [decimal](10, 2) NOT NULL,
	[status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_course] PRIMARY KEY CLUSTERED
(
	[courseid] ASC
)
)

SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[followup](
	[followupid] [int] IDENTITY(1,1) NOT NULL,
	[membercourseid] [int] NOT NULL,
	[coachid] [int] NOT NULL,
	[status] [nvarchar](20) NULL,
	[contactmethod] [nvarchar](20) NULL,
	[note] [nvarchar](max) NULL,
	[createdate] [datetime] NULL,
 CONSTRAINT [PK_followup] PRIMARY KEY CLUSTERED
(
	[followupid] ASC
)
)

SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[inbodyrecords](
	[inbodyid] [int] IDENTITY(1,1) NOT NULL,
    [attendanceid] [int] NOT NULL,
	[memberid] [int] NOT NULL,
	[recorddate] [date] NULL,
	[weight] [decimal](5, 2) NULL,
	[bodyfatpct] [decimal](4, 1) NULL,
	[musclemass] [decimal](4, 1) NULL,
 CONSTRAINT [PK_inbodyrecords] PRIMARY KEY CLUSTERED
(
	[inbodyid] ASC
)
)

SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[member](
	[memberid] [int] IDENTITY(1,1) NOT NULL,
	[accountid] [int] NOT NULL,
	[memberno] [nvarchar](20) NOT NULL,
	[name] [nvarchar](50) NOT NULL,
	[gender] [nvarchar](10) NOT NULL,
	[phone] [nvarchar](50) NOT NULL,
	[email] [nvarchar](100) NOT NULL,
	[birthday] [date] NOT NULL,
    [avatarurl] [nvarchar](500) NULL,
	[status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_member] PRIMARY KEY CLUSTERED
(
	[memberid] ASC
)
)

SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[membercourse](
	[membercourseid] [int] IDENTITY(1,1) NOT NULL,
    [coachid] [int] NOT NULL,
	[memberid] [int] NOT NULL,
	[courseid] [int] NOT NULL,
	[purchasedate] [date] NOT NULL,
	[totalsessions] [int] NOT NULL,
	[remainingsessions] [int] NOT NULL,
	[status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_membercourse] PRIMARY KEY CLUSTERED
(
	[membercourseid] ASC
)
)

SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[renewal](
    [renewalid] [int] IDENTITY(1,1) NOT NULL,
    [membercourseid] [int] NOT NULL,
    [newmembercourseid] [int] NOT NULL,
    [renewaldate] [datetime] NOT NULL,
    [addedsessions] [int] NOT NULL,
    [amount] [int] NOT NULL,
    [paymentmethod] [nvarchar](50) NOT NULL,
    [note] [nvarchar](500) NULL,
    CONSTRAINT [PK_renewal] PRIMARY KEY CLUSTERED ([renewalid] ASC),
    CONSTRAINT [UQ_renewal_newmembercourseid] UNIQUE ([newmembercourseid]),
    CONSTRAINT [CK_renewal_different_courses] CHECK ([membercourseid] <> [newmembercourseid]),
    CONSTRAINT [CK_renewal_values] CHECK ([addedsessions] > 0 AND [amount] >= 0)
)

SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[useraccount](
	[accountid] [int] IDENTITY(1,1) NOT NULL,
	[username] [nvarchar](50) NOT NULL,
	[password] [nvarchar](200) NOT NULL,
	[role] [nvarchar](50) NOT NULL,
	[status] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_useraccount_1] PRIMARY KEY CLUSTERED
(
	[accountid] ASC
)
)

ALTER TABLE [dbo].[attendance] ADD  CONSTRAINT [DF_attendance_attendancestatus]  DEFAULT (N''PENDING'') FOR [attendancestatus]

ALTER TABLE [dbo].[classschedule] ADD  CONSTRAINT [DF_classschedule_status]  DEFAULT (N''open'') FOR [status]

ALTER TABLE [dbo].[coach] ADD  CONSTRAINT [DF_coach_status]  DEFAULT (N''active'') FOR [status]

ALTER TABLE [dbo].[member] ADD  CONSTRAINT [DF_member_status]  DEFAULT (N''active'') FOR [status]

ALTER TABLE [dbo].[membercourse] ADD  CONSTRAINT [DF_membercourse_status]  DEFAULT (N''active'') FOR [status]

ALTER TABLE [dbo].[useraccount] ADD  CONSTRAINT [DF_useraccount_status]  DEFAULT (N''active'') FOR [status]

ALTER TABLE [dbo].[attendance]  WITH CHECK ADD  CONSTRAINT [FK_attendance_booking] FOREIGN KEY([bookingid])
REFERENCES [dbo].[booking] ([bookingid])
ON UPDATE CASCADE
ON DELETE CASCADE

ALTER TABLE [dbo].[attendance] CHECK CONSTRAINT [FK_attendance_booking]

ALTER TABLE [dbo].[booking]  WITH CHECK ADD  CONSTRAINT [FK_booking_classschedule] FOREIGN KEY([scheduleid])
REFERENCES [dbo].[classschedule] ([scheduleid])

ALTER TABLE [dbo].[booking] CHECK CONSTRAINT [FK_booking_classschedule]

ALTER TABLE [dbo].[booking]  WITH CHECK ADD  CONSTRAINT [FK_booking_membercourse] FOREIGN KEY([membercourseid])
REFERENCES [dbo].[membercourse] ([membercourseid])

ALTER TABLE [dbo].[booking] CHECK CONSTRAINT [FK_booking_membercourse]

ALTER TABLE [dbo].[classschedule]  WITH CHECK ADD  CONSTRAINT [FK_classschedule_coach] FOREIGN KEY([coachid])
REFERENCES [dbo].[coach] ([coachid])

ALTER TABLE [dbo].[classschedule] CHECK CONSTRAINT [FK_classschedule_coach]

ALTER TABLE [dbo].[classschedule]  WITH CHECK ADD  CONSTRAINT [FK_classschedule_course] FOREIGN KEY([courseid])
REFERENCES [dbo].[course] ([courseid])
ON UPDATE CASCADE
ON DELETE CASCADE

ALTER TABLE [dbo].[classschedule] CHECK CONSTRAINT [FK_classschedule_course]

ALTER TABLE [dbo].[coach]  WITH CHECK ADD  CONSTRAINT [FK_coach_useraccount] FOREIGN KEY([accountid])
REFERENCES [dbo].[useraccount] ([accountid])

ALTER TABLE [dbo].[coach] CHECK CONSTRAINT [FK_coach_useraccount]

ALTER TABLE [dbo].[coachcourse]  WITH CHECK ADD  CONSTRAINT [FK_coachcourse_coach] FOREIGN KEY([coachid])
REFERENCES [dbo].[coach] ([coachid])

ALTER TABLE [dbo].[coachcourse] CHECK CONSTRAINT [FK_coachcourse_coach]

ALTER TABLE [dbo].[coachcourse]  WITH CHECK ADD  CONSTRAINT [FK_coachcourse_course] FOREIGN KEY([courseid])
REFERENCES [dbo].[course] ([courseid])

ALTER TABLE [dbo].[coachcourse] CHECK CONSTRAINT [FK_coachcourse_course]

ALTER TABLE [dbo].[followup]  WITH CHECK ADD  CONSTRAINT [FK_followup_coach] FOREIGN KEY([coachid])
REFERENCES [dbo].[coach] ([coachid])

ALTER TABLE [dbo].[followup] CHECK CONSTRAINT [FK_followup_coach]

ALTER TABLE [dbo].[followup]  WITH CHECK ADD  CONSTRAINT [FK_followup_membercourse] FOREIGN KEY([membercourseid])
REFERENCES [dbo].[membercourse] ([membercourseid])
ON UPDATE CASCADE
ON DELETE CASCADE

ALTER TABLE [dbo].[followup] CHECK CONSTRAINT [FK_followup_membercourse]

ALTER TABLE [dbo].[inbodyrecords]  WITH CHECK ADD  CONSTRAINT [FK_inbody_member] FOREIGN KEY([memberid])
REFERENCES [dbo].[member] ([memberid])
ON UPDATE CASCADE
ON DELETE CASCADE

ALTER TABLE [dbo].[inbodyrecords] CHECK CONSTRAINT [FK_inbody_member]

ALTER TABLE [dbo].[member]  WITH CHECK ADD  CONSTRAINT [FK_member_useraccount] FOREIGN KEY([accountid])
REFERENCES [dbo].[useraccount] ([accountid])

ALTER TABLE [dbo].[member] CHECK CONSTRAINT [FK_member_useraccount]

ALTER TABLE [dbo].[membercourse]  WITH CHECK ADD  CONSTRAINT [FK_membercourse_course] FOREIGN KEY([courseid])
REFERENCES [dbo].[course] ([courseid])

ALTER TABLE [dbo].[membercourse] CHECK CONSTRAINT [FK_membercourse_course]

ALTER TABLE [dbo].[membercourse]  WITH CHECK ADD  CONSTRAINT [FK_membercourse_member] FOREIGN KEY([memberid])
REFERENCES [dbo].[member] ([memberid])

ALTER TABLE [dbo].[membercourse] CHECK CONSTRAINT [FK_membercourse_member]

ALTER TABLE [dbo].[renewal]  WITH CHECK ADD  CONSTRAINT [FK_renewal_membercourse] FOREIGN KEY([membercourseid])
REFERENCES [dbo].[membercourse] ([membercourseid])

ALTER TABLE [dbo].[renewal] CHECK CONSTRAINT [FK_renewal_membercourse]
ALTER TABLE [dbo].[renewal] WITH CHECK ADD CONSTRAINT [FK_renewal_newmembercourse]
FOREIGN KEY([newmembercourseid]) REFERENCES [dbo].[membercourse] ([membercourseid])

ALTER TABLE [dbo].[renewal] CHECK CONSTRAINT [FK_renewal_newmembercourse]
-- DEBUG原因：V1 對不存在的 attendanceid 做 ALTER COLUMN；直接建立 NOT NULL 欄位與外鍵。
ALTER TABLE dbo.inbodyrecords ADD CONSTRAINT FK_inbodyrecords_attendance FOREIGN KEY(attendanceid) REFERENCES dbo.attendance(attendanceid);
-- 整理原因：納入 V1 的每筆預約最多一筆出席及 V3 的每筆出席最多一筆 InBody。
ALTER TABLE dbo.attendance ADD CONSTRAINT UQ_attendance_bookingid UNIQUE(bookingid);
ALTER TABLE dbo.inbodyrecords ADD CONSTRAINT UQ_inbodyrecords_attendanceid UNIQUE(attendanceid);
ALTER TABLE dbo.membercourse ADD CONSTRAINT FK_membercourse_coach FOREIGN KEY(coachid) REFERENCES dbo.coach(coachid);
-- DEBUG原因：避免重複業務編號造成測試資料 JOIN 多筆及錯誤關聯。
ALTER TABLE dbo.useraccount ADD CONSTRAINT UQ_useraccount_username UNIQUE(username);
ALTER TABLE dbo.coach ADD CONSTRAINT UQ_coach_coachno UNIQUE(coachno), CONSTRAINT UQ_coach_accountid UNIQUE(accountid);
ALTER TABLE dbo.member ADD CONSTRAINT UQ_member_memberno UNIQUE(memberno), CONSTRAINT UQ_member_accountid UNIQUE(accountid);
ALTER TABLE dbo.course ADD CONSTRAINT UQ_course_coursename UNIQUE(coursename);
-- DEBUG原因：購課與排課只能使用 coachcourse 已登錄的授課配對。
ALTER TABLE dbo.classschedule ADD CONSTRAINT FK_classschedule_coachcourse FOREIGN KEY(coachid,courseid) REFERENCES dbo.coachcourse(coachid,courseid);
ALTER TABLE dbo.membercourse ADD CONSTRAINT FK_membercourse_coachcourse FOREIGN KEY(coachid,courseid) REFERENCES dbo.coachcourse(coachid,courseid);
ALTER TABLE dbo.classschedule ADD CONSTRAINT CK_classschedule_time CHECK(endtime > starttime);
ALTER TABLE dbo.course ADD CONSTRAINT CK_course_values CHECK(durationmin > 0 AND price >= 0);
ALTER TABLE dbo.membercourse ADD CONSTRAINT CK_membercourse_sessions CHECK(totalsessions > 0 AND remainingsessions BETWEEN 0 AND totalsessions);
-- 整理原因：淘汰 text，改用可儲存中文的 nvarchar(max)；課程 status 改為無補空白的 nvarchar。';
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
