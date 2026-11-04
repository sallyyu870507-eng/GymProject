/*
團隊展示：單一 RESET + 建表 + 假資料 + 驗證，修訂 TEAM-RESET-20261102-R4。
目標僅限 gymproject_seed_verify_20261030；不存取原 gymproject。
警告：本檔會刪除目標隔離庫的12張表及全部資料，再重建與匯入。
停止連到此隔離庫的後端後才執行；成功後不要在已有操作成果時重跑。
結構：原附件 01_reset_and_seed(2).sql 的 DDL 原文；未改欄位、約束或外鍵。
資料：上傳 team_demo_seed.sql，保留教練/課程/配對及情境，修正51219誤擋usedup。
程式分析來源：be70153c1be44b6e3f9d0c4d3d40b5ed2394ef3c（依原Codex報告，未重新抓Git）。
日期窗：初始化限台北2026-10-30至2026-11-13；固定預約資料至11-13；教練班表至12-13。
測試密碼（所有帳號，僅開發用）：GymDemo2026!
AMY帳號 coach_amy；會員 member001..member035；管理員 admin_demo。
本檔尚未在SQL Server實際執行；Python排程模型檢查不等於SQL/API驗證。
交付版：已整合 AMY 會員 member001..member015 的 /avatars/memberNNN.jpg 路徑，及會員012..015新姓名。
只需執行本 SQL，不需要另外執行照片或姓名 UPDATE。圖片檔另放 frontend/public/avatars。
本交付版僅靜態核對，未在此環境連線 SQL Server 執行。
SSMS初始化時請整份執行，不選取局部片段；會清除目標隔離庫既有操作成果。
*/
USE [master];
GO
IF DB_ID(N'gymproject_seed_verify_20261030') IS NULL
    EXEC(N'CREATE DATABASE [gymproject_seed_verify_20261030]');
GO
USE [gymproject_seed_verify_20261030];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME()<>N'gymproject_seed_verify_20261030'
    THROW 51300,N'目標不是指定隔離測試庫，已停止。',1;
IF @@TRANCOUNT<>0
    THROW 51301,N'請先結束既有交易；已停止，未進行RESET。',1;
DECLARE @RunAsOf datetime2(0)=CONVERT(datetime2(0),
    (SYSUTCDATETIME() AT TIME ZONE 'UTC') AT TIME ZONE 'Taipei Standard Time');
IF CONVERT(date,@RunAsOf) NOT BETWEEN CONVERT(date,'20261030',112) AND CONVERT(date,'20261113',112)
    THROW 51302,N'超出固定展示日期窗，未進行RESET。',1;
PRINT N'Revision=TEAM-RESET-20261102-R4';
PRINT N'TargetDatabase='+DB_NAME();
PRINT N'SeedAsOf(Taipei)='+CONVERT(nvarchar(19),@RunAsOf,126);
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @Expected TABLE(name sysname PRIMARY KEY);
    INSERT @Expected VALUES (N'attendance'),(N'booking'),(N'classschedule'),(N'coach'),(N'coachcourse'),(N'course'),(N'followup'),(N'inbodyrecords'),(N'member'),(N'membercourse'),(N'renewal'),(N'useraccount');
    IF EXISTS(SELECT 1 FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id
      WHERE t.is_ms_shipped=0 AND (s.name<>N'dbo' OR NOT EXISTS(SELECT 1 FROM @Expected e WHERE e.name=t.name)))
        THROW 51102,N'存在 12 張測試表以外的資料表，已停止。',1;
    IF EXISTS(SELECT 1 FROM sys.objects WHERE is_ms_shipped=0 AND type IN('V','P','FN','IF','TF','TR'))
        THROW 51103,N'存在額外檢視／程序／函式／觸發器，請先檢查相依性。',1;
    DECLARE @Drop nvarchar(max)=N'';
    SELECT @Drop=@Drop+N'ALTER TABLE '+QUOTENAME(s.name)+N'.'+QUOTENAME(t.name)
      +N' DROP CONSTRAINT '+QUOTENAME(f.name)+N';'+NCHAR(10)
    FROM sys.foreign_keys f JOIN sys.tables t ON t.object_id=f.parent_object_id
    JOIN sys.schemas s ON s.schema_id=t.schema_id WHERE t.is_ms_shipped=0;
    EXEC sys.sp_executesql @Drop;
    SET @Drop=N'';
    SELECT @Drop=@Drop+N'DROP TABLE dbo.'+QUOTENAME(t.name)+N';'+NCHAR(10)
      FROM sys.tables t WHERE t.is_ms_shipped=0;
    EXEC sys.sp_executesql @Drop;

    -- Original DDL, executed in a separate compile scope.
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_attendance_bookingid] UNIQUE NONCLUSTERED
(
	[bookingid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

/****** 物件:  Table [dbo].[booking]    指令碼日期: 2026/10/29 上午 11:20:05 ******/
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

/****** 物件:  Table [dbo].[classschedule]    指令碼日期: 2026/10/29 上午 11:20:05 ******/
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

/****** 物件:  Table [dbo].[coach]    指令碼日期: 2026/10/29 上午 11:20:05 ******/
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_coach_accountid] UNIQUE NONCLUSTERED
(
	[accountid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_coach_coachno] UNIQUE NONCLUSTERED
(
	[coachno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

/****** 物件:  Table [dbo].[coachcourse]    指令碼日期: 2026/10/29 上午 11:20:05 ******/
SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[coachcourse](
	[coachid] [int] NOT NULL,
	[courseid] [int] NOT NULL,
 CONSTRAINT [PK_coachcourse] PRIMARY KEY CLUSTERED
(
	[coachid] ASC,
	[courseid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

/****** 物件:  Table [dbo].[course]    指令碼日期: 2026/10/29 上午 11:20:05 ******/
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_course_coursename] UNIQUE NONCLUSTERED
(
	[coursename] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

/****** 物件:  Table [dbo].[followup]    指令碼日期: 2026/10/29 上午 11:20:05 ******/
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

/****** 物件:  Table [dbo].[inbodyrecords]    指令碼日期: 2026/10/29 上午 11:20:05 ******/
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_inbodyrecords_attendanceid] UNIQUE NONCLUSTERED
(
	[attendanceid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

/****** 物件:  Table [dbo].[member]    指令碼日期: 2026/10/29 上午 11:20:05 ******/
SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON

CREATE TABLE [dbo].[member](
	[memberid] [int] IDENTITY(1,1) NOT NULL,
	[accountid] [int] NOT NULL,
	[memberno] [nvarchar](20) NULL,
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_member_accountid] UNIQUE NONCLUSTERED
(
	[accountid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_member_memberno] UNIQUE NONCLUSTERED
(
	[memberno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

/****** 物件:  Table [dbo].[membercourse]    指令碼日期: 2026/10/29 上午 11:20:05 ******/
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

/****** 物件:  Table [dbo].[renewal]    指令碼日期: 2026/10/29 上午 11:20:05 ******/
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
 CONSTRAINT [PK_renewal] PRIMARY KEY CLUSTERED
(
	[renewalid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_renewal_newmembercourseid] UNIQUE NONCLUSTERED
(
	[newmembercourseid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

/****** 物件:  Table [dbo].[useraccount]    指令碼日期: 2026/10/29 上午 11:20:05 ******/
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_useraccount_username] UNIQUE NONCLUSTERED
(
	[username] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

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

ALTER TABLE [dbo].[classschedule]  WITH CHECK ADD  CONSTRAINT [FK_classschedule_coachcourse] FOREIGN KEY([coachid], [courseid])
REFERENCES [dbo].[coachcourse] ([coachid], [courseid])

ALTER TABLE [dbo].[classschedule] CHECK CONSTRAINT [FK_classschedule_coachcourse]

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

ALTER TABLE [dbo].[inbodyrecords]  WITH CHECK ADD  CONSTRAINT [FK_inbodyrecords_attendance] FOREIGN KEY([attendanceid])
REFERENCES [dbo].[attendance] ([attendanceid])

ALTER TABLE [dbo].[inbodyrecords] CHECK CONSTRAINT [FK_inbodyrecords_attendance]

ALTER TABLE [dbo].[member]  WITH CHECK ADD  CONSTRAINT [FK_member_useraccount] FOREIGN KEY([accountid])
REFERENCES [dbo].[useraccount] ([accountid])

ALTER TABLE [dbo].[member] CHECK CONSTRAINT [FK_member_useraccount]

ALTER TABLE [dbo].[membercourse]  WITH CHECK ADD  CONSTRAINT [FK_membercourse_coach] FOREIGN KEY([coachid])
REFERENCES [dbo].[coach] ([coachid])

ALTER TABLE [dbo].[membercourse] CHECK CONSTRAINT [FK_membercourse_coach]

ALTER TABLE [dbo].[membercourse]  WITH CHECK ADD  CONSTRAINT [FK_membercourse_coachcourse] FOREIGN KEY([coachid], [courseid])
REFERENCES [dbo].[coachcourse] ([coachid], [courseid])

ALTER TABLE [dbo].[membercourse] CHECK CONSTRAINT [FK_membercourse_coachcourse]

ALTER TABLE [dbo].[membercourse]  WITH CHECK ADD  CONSTRAINT [FK_membercourse_course] FOREIGN KEY([courseid])
REFERENCES [dbo].[course] ([courseid])

ALTER TABLE [dbo].[membercourse] CHECK CONSTRAINT [FK_membercourse_course]

ALTER TABLE [dbo].[membercourse]  WITH CHECK ADD  CONSTRAINT [FK_membercourse_member] FOREIGN KEY([memberid])
REFERENCES [dbo].[member] ([memberid])

ALTER TABLE [dbo].[membercourse] CHECK CONSTRAINT [FK_membercourse_member]

ALTER TABLE [dbo].[renewal]  WITH CHECK ADD  CONSTRAINT [FK_renewal_membercourse] FOREIGN KEY([membercourseid])
REFERENCES [dbo].[membercourse] ([membercourseid])

ALTER TABLE [dbo].[renewal] CHECK CONSTRAINT [FK_renewal_membercourse]

ALTER TABLE [dbo].[renewal]  WITH CHECK ADD  CONSTRAINT [FK_renewal_newmembercourse] FOREIGN KEY([newmembercourseid])
REFERENCES [dbo].[membercourse] ([membercourseid])

ALTER TABLE [dbo].[renewal] CHECK CONSTRAINT [FK_renewal_newmembercourse]

ALTER TABLE [dbo].[classschedule]  WITH CHECK ADD  CONSTRAINT [CK_classschedule_time] CHECK  (([endtime]>[starttime]))

ALTER TABLE [dbo].[classschedule] CHECK CONSTRAINT [CK_classschedule_time]

ALTER TABLE [dbo].[course]  WITH CHECK ADD  CONSTRAINT [CK_course_values] CHECK  (([durationmin]>(0) AND [price]>=(0)))

ALTER TABLE [dbo].[course] CHECK CONSTRAINT [CK_course_values]

ALTER TABLE [dbo].[membercourse]  WITH CHECK ADD  CONSTRAINT [CK_membercourse_sessions] CHECK  (([totalsessions]>(0) AND ([remainingsessions]>=(0) AND [remainingsessions]<=[totalsessions])))

ALTER TABLE [dbo].[membercourse] CHECK CONSTRAINT [CK_membercourse_sessions]

ALTER TABLE [dbo].[renewal]  WITH CHECK ADD  CONSTRAINT [CK_renewal_different_courses] CHECK  (([membercourseid]<>[newmembercourseid]))

ALTER TABLE [dbo].[renewal] CHECK CONSTRAINT [CK_renewal_different_courses]

ALTER TABLE [dbo].[renewal]  WITH CHECK ADD  CONSTRAINT [CK_renewal_values] CHECK  (([addedsessions]>(0) AND [amount]>=(0)))

ALTER TABLE [dbo].[renewal] CHECK CONSTRAINT [CK_renewal_values]
';
    -- Data and pre-commit validation share the outer RESET transaction.
    EXEC sys.sp_executesql N'    DECLARE @SeedDate date = CONVERT(date, @SeedAsOf);
    IF @SeedDate < CONVERT(date,''20261030'',112)
       OR @SeedDate > CONVERT(date,''20261113'',112)
        THROW 51202, N''固定展示資料僅適用 2026-10-30 至 2026-11-13；已停止。'', 1;
    PRINT N''SeedAsOf(Taipei)='' + CONVERT(nvarchar(19), @SeedAsOf, 126);

    DECLARE @Required TABLE (TableName sysname PRIMARY KEY);
    INSERT @Required VALUES
      (N''attendance''),(N''booking''),(N''classschedule''),(N''coach''),
      (N''coachcourse''),(N''course''),(N''followup''),(N''inbodyrecords''),
      (N''member''),(N''membercourse''),(N''renewal''),(N''useraccount'');
    IF (SELECT COUNT(*) FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id
        WHERE s.name=N''dbo'' AND t.is_ms_shipped=0) <> 12
        THROW 51203, N''dbo 資料表數量不是預期的 12 張；已停止。'', 1;
    IF EXISTS (SELECT 1 FROM @Required r WHERE OBJECT_ID(N''dbo.''+QUOTENAME(r.TableName),N''U'') IS NULL)
        THROW 51204, N''缺少必要 dbo 資料表；請先核對附件結構。'', 1;

    DECLARE @TableName sysname, @Sql nvarchar(max), @Rows bigint;
    DECLARE table_check CURSOR LOCAL FAST_FORWARD FOR SELECT TableName FROM @Required ORDER BY TableName;
    OPEN table_check;
    FETCH NEXT FROM table_check INTO @TableName;
    WHILE @@FETCH_STATUS=0
    BEGIN
        SET @Sql=N''SELECT @n=COUNT_BIG(*) FROM dbo.''+QUOTENAME(@TableName)+N'' WITH (TABLOCKX,HOLDLOCK);'';
        EXEC sys.sp_executesql @Sql,N''@n bigint OUTPUT'',@n=@Rows OUTPUT;
        IF @Rows<>0 THROW 51205, N''有必要資料表非空；本 seed 不會清除或覆寫資料。'', 1;
        FETCH NEXT FROM table_check INTO @TableName;
    END;
    CLOSE table_check; DEALLOCATE table_check;

    DECLARE @PasswordHash nvarchar(200)=N''$2a$12$C3VEW2zUyLB0V7keX.1LC.YCJHcG4nLe14hsC5P5n6uqOQV5Xb4dK'';
    DECLARE @People TABLE(n int PRIMARY KEY, memberno nvarchar(20) UNIQUE,
        username nvarchar(50) UNIQUE, FullName nvarchar(50), Gender nvarchar(10));
    INSERT @People VALUES
    (1,N''M001'',N''member001'',N''陳怡君'',N''女''),(2,N''M002'',N''member002'',N''林志豪'',N''男''),
    (3,N''M003'',N''member003'',N''黃雅婷'',N''女''),(4,N''M004'',N''member004'',N''張家豪'',N''男''),
    (5,N''M005'',N''member005'',N''李佳穎'',N''女''),(6,N''M006'',N''member006'',N''王俊傑'',N''男''),
    (7,N''M007'',N''member007'',N''吳佩珊'',N''女''),(8,N''M008'',N''member008'',N''劉冠廷'',N''男''),
    (9,N''M009'',N''member009'',N''蔡依庭'',N''女''),(10,N''M010'',N''member010'',N''楊承翰'',N''男''),
    (11,N''M011'',N''member011'',N''許庭瑋'',N''女''),(12,N''M012'',N''member012'',N''鄭宇翔'',N''男''),
    (13,N''M013'',N''member013'',N''謝雅雯'',N''女''),(14,N''M014'',N''member014'',N''洪冠宇'',N''男''),
    (15,N''M015'',N''member015'',N''郭欣妤'',N''女''),(16,N''M016'',N''member016'',N''邱婉婷'',N''女''),
    (17,N''M017'',N''member017'',N''曾子軒'',N''男''),(18,N''M018'',N''member018'',N''廖欣怡'',N''女''),
    (19,N''M019'',N''member019'',N''賴冠宇'',N''男''),(20,N''M020'',N''member020'',N''徐雅雯'',N''女''),
    (21,N''M021'',N''member021'',N''周育誠'',N''男''),(22,N''M022'',N''member022'',N''葉思妤'',N''女''),
    (23,N''M023'',N''member023'',N''蘇哲宇'',N''男''),(24,N''M024'',N''member024'',N''莊雅涵'',N''女''),
    (25,N''M025'',N''member025'',N''呂柏翰'',N''男''),(26,N''M026'',N''member026'',N''江宜蓁'',N''女''),
    (27,N''M027'',N''member027'',N''何家瑋'',N''男''),(28,N''M028'',N''member028'',N''蕭佳蓉'',N''女''),
    (29,N''M029'',N''member029'',N''羅宇翔'',N''男''),(30,N''M030'',N''member030'',N''高詩涵'',N''女''),
    (31,N''M031'',N''member031'',N''傅子晴'',N''女''),(32,N''M032'',N''member032'',N''沈柏廷'',N''男''),
    (33,N''M033'',N''member033'',N''簡佩瑜'',N''女''),(34,N''M034'',N''member034'',N''鍾明哲'',N''男''),
    (35,N''M035'',N''member035'',N''戴欣妤'',N''女'');

    DECLARE @Coaches TABLE(coachno nvarchar(20) PRIMARY KEY, username nvarchar(50) UNIQUE,
        FullName nvarchar(50),Gender nvarchar(10),Phone nvarchar(50),Email nvarchar(100),Specialty nvarchar(100));
    INSERT @Coaches VALUES
      (N''C001'',N''coach_amy'',N''AMY'',N''女'',N''0912345601'',N''amy@example.com'',N''初階重訓、中階重訓、TRX''),
      (N''C002'',N''coach_ben'',N''BEN'',N''男'',N''0923456702'',N''ben@example.com'',N''筋膜放鬆''),
      (N''C003'',N''coach_chris'',N''CHRIS'',N''男'',N''0934567803'',N''chris@example.com'',N''中階重訓、高階重訓''),
      (N''C004'',N''coach_david'',N''DAVID'',N''男'',N''0945678904'',N''david@example.com'',N''初階重訓、筋膜放鬆''),
      (N''C005'',N''coach_eric'',N''ERIC'',N''男'',N''0956789005'',N''eric@example.com'',N''高階重訓、TRX'');
    DECLARE @CourseCatalog TABLE(CourseName nvarchar(100) PRIMARY KEY,CourseType nvarchar(50),
        Description nvarchar(max),DurationMin int,Price decimal(10,2),Status nvarchar(20));
    INSERT @CourseCatalog VALUES
      (N''初階重訓'',N''重量訓練'',N''適合初學者的重量訓練課程，每堂 60 分鐘。'',60,1000.00,N''active''),
      (N''中階重訓'',N''重量訓練'',N''適合已有基礎、想進一步提升肌力的學員。'',60,1300.00,N''active''),
      (N''高階重訓'',N''重量訓練'',N''適合有訓練經驗、想挑戰強度的學員。'',60,1500.00,N''active''),
      (N''筋膜放鬆'',N''伸展放鬆'',N''透過筋膜放鬆練習，舒緩運動後的緊繃感。'',60,1100.00,N''active''),
      (N''TRX'',N''懸吊訓練'',N''利用懸吊器材進行全身訓練，提升核心與肌力。'',60,1200.00,N''active'');
    DECLARE @PairCatalog TABLE(coachno nvarchar(20),Course1 nvarchar(100),Course2 nvarchar(100) NULL,Course3 nvarchar(100) NULL);
    INSERT @PairCatalog VALUES
      (N''C001'',N''初階重訓'',N''中階重訓'',N''TRX''),(N''C002'',N''筋膜放鬆'',NULL,NULL),
      (N''C003'',N''中階重訓'',N''高階重訓'',NULL),(N''C004'',N''初階重訓'',N''筋膜放鬆'',NULL),
      (N''C005'',N''高階重訓'',N''TRX'',NULL);

    DECLARE @UserCatalog TABLE(username nvarchar(50) PRIMARY KEY,role nvarchar(50));
    INSERT @UserCatalog VALUES (N''admin_demo'',N''admin'');
    INSERT @UserCatalog SELECT username,N''coach'' FROM @Coaches;
    INSERT @UserCatalog SELECT username,N''member'' FROM @People;
    DECLARE @AccountMap TABLE(username nvarchar(50) PRIMARY KEY,accountid int NOT NULL);
    INSERT dbo.useraccount(username,password,role,status)
      OUTPUT inserted.username,inserted.accountid INTO @AccountMap(username,accountid)
      SELECT username,@PasswordHash,role,N''active'' FROM @UserCatalog;

    DECLARE @CoachMap TABLE(coachno nvarchar(20) PRIMARY KEY,coachid int NOT NULL);
    INSERT dbo.coach(accountid,coachno,name,gender,phone,email,specialty,status)
      OUTPUT inserted.coachno,inserted.coachid INTO @CoachMap(coachno,coachid)
      SELECT a.accountid,c.coachno,c.FullName,c.Gender,c.Phone,c.Email,c.Specialty,N''active''
      FROM @Coaches c JOIN @AccountMap a ON a.username=c.username;
    DECLARE @MemberMap TABLE(memberno nvarchar(20) PRIMARY KEY,memberid int NOT NULL);
    INSERT dbo.member(accountid,memberno,name,gender,phone,email,birthday,avatarurl,status)
      OUTPUT inserted.memberno,inserted.memberid INTO @MemberMap(memberno,memberid)
         SELECT a.accountid,p.memberno,p.FullName,p.Gender,
        N''0900000''+RIGHT(N''000''+CONVERT(nvarchar(3),p.n),3),
        p.username+N''@example.invalid'',
        DATEFROMPARTS(1985+(p.n%15),1+((p.n*3)%12),1+((p.n*7)%27)),
        CASE
          WHEN p.n BETWEEN 1 AND 15
            THEN N''/avatars/''+p.username+N''.jpg''
          ELSE NULL
        END,
        N''active''
      FROM @People p JOIN @AccountMap a ON a.username=p.username;

    DECLARE @CourseMap TABLE(CourseName nvarchar(100) PRIMARY KEY,courseid int NOT NULL);
    INSERT dbo.course(coursename,coursetype,description,durationmin,price,status)
      OUTPUT inserted.coursename,inserted.courseid INTO @CourseMap(CourseName,courseid)
      SELECT CourseName,CourseType,Description,DurationMin,Price,Status FROM @CourseCatalog;
    INSERT dbo.coachcourse(coachid,courseid)
      SELECT cm.coachid,co.courseid
      FROM @PairCatalog p JOIN @CoachMap cm ON cm.coachno=p.coachno
      CROSS APPLY (VALUES(p.Course1),(p.Course2),(p.Course3)) v(CourseName)
      JOIN @CourseMap co ON co.CourseName=v.CourseName
      WHERE v.CourseName IS NOT NULL;

    DECLARE @PlanCatalog TABLE(PlanKey nvarchar(40) PRIMARY KEY,memberno nvarchar(20),coachno nvarchar(20),
      CourseName nvarchar(100),TotalSessions int,PurchaseDate date);
    INSERT @PlanCatalog VALUES
      (N''A001_BASE'',N''M001'',N''C001'',N''初階重訓'',24,''20260901''),(N''A001_PURCHASE'',N''M001'',N''C001'',N''初階重訓'',24,''20261020''),
      (N''A002_BASE'',N''M002'',N''C001'',N''中階重訓'',30,''20260901''),(N''A003_BASE'',N''M003'',N''C001'',N''初階重訓'',20,''20260901''),
      (N''A004_BASE'',N''M004'',N''C001'',N''TRX'',24,''20260901''),(N''A005_BASE'',N''M005'',N''C001'',N''中階重訓'',20,''20260901''),
      (N''A006_BASE'',N''M006'',N''C001'',N''TRX'',24,''20260901''),(N''A007_BASE'',N''M007'',N''C001'',N''初階重訓'',20,''20260901''),
      (N''A007_TRX'',N''M007'',N''C001'',N''TRX'',24,''20260901''),(N''A008_BASE'',N''M008'',N''C001'',N''中階重訓'',24,''20260901''),
      (N''A009_BASE'',N''M009'',N''C001'',N''TRX'',30,''20260901''),(N''A009_R1'',N''M009'',N''C001'',N''TRX'',20,''20261010''),
      (N''A009_R2'',N''M009'',N''C001'',N''TRX'',24,''20261020''),(N''A010_BASE'',N''M010'',N''C001'',N''初階重訓'',20,''20260901''),
      (N''A011_BASE'',N''M011'',N''C001'',N''初階重訓'',24,''20260901''),(N''A011_NEW'',N''M011'',N''C001'',N''初階重訓'',20,''20261010''),
      (N''A012_BASE'',N''M012'',N''C001'',N''TRX'',20,''20260901''),(N''A012_NEW'',N''M012'',N''C001'',N''初階重訓'',30,''20261010''),
      (N''A013_BASE'',N''M013'',N''C001'',N''中階重訓'',20,''20260901''),(N''A013_NEW'',N''M013'',N''C001'',N''中階重訓'',24,''20261020''),
      (N''A014_BASE'',N''M014'',N''C001'',N''初階重訓'',24,''20260901''),(N''A015_BASE'',N''M015'',N''C001'',N''TRX'',30,''20260901''),
      (N''B016_BASE'',N''M016'',N''C002'',N''筋膜放鬆'',24,''20260901''),(N''B017_BASE'',N''M017'',N''C002'',N''筋膜放鬆'',24,''20260901''),
      (N''B018_BASE'',N''M018'',N''C002'',N''筋膜放鬆'',24,''20260901''),(N''B019_BASE'',N''M019'',N''C002'',N''筋膜放鬆'',24,''20260901''),
      (N''B020_BASE'',N''M020'',N''C002'',N''筋膜放鬆'',24,''20260901''),(N''C021_BASE'',N''M021'',N''C003'',N''中階重訓'',24,''20260901''),
      (N''C022_BASE'',N''M022'',N''C003'',N''高階重訓'',24,''20260901''),(N''C023_BASE'',N''M023'',N''C003'',N''中階重訓'',24,''20260901''),
      (N''C024_BASE'',N''M024'',N''C003'',N''高階重訓'',24,''20260901''),(N''C025_BASE'',N''M025'',N''C003'',N''中階重訓'',24,''20260901''),
      (N''D026_BASE'',N''M026'',N''C004'',N''初階重訓'',24,''20260901''),(N''D027_BASE'',N''M027'',N''C004'',N''筋膜放鬆'',24,''20260901''),
      (N''D028_BASE'',N''M028'',N''C004'',N''初階重訓'',24,''20260901''),(N''D029_BASE'',N''M029'',N''C004'',N''筋膜放鬆'',24,''20260901''),
      (N''D030_BASE'',N''M030'',N''C004'',N''初階重訓'',24,''20260901''),(N''E031_BASE'',N''M031'',N''C005'',N''高階重訓'',24,''20260901''),
      (N''E032_BASE'',N''M032'',N''C005'',N''TRX'',24,''20260901''),(N''E033_BASE'',N''M033'',N''C005'',N''高階重訓'',24,''20260901''),
      (N''E034_BASE'',N''M034'',N''C005'',N''TRX'',24,''20260901''),(N''E035_BASE'',N''M035'',N''C005'',N''高階重訓'',24,''20260901'');
    DECLARE @PlanMap TABLE(PlanKey nvarchar(40) PRIMARY KEY,membercourseid int,memberno nvarchar(20),
      coachno nvarchar(20),CourseName nvarchar(100),TotalSessions int);
    DECLARE @PlanKey nvarchar(40),@MemberNo nvarchar(20),@CoachNo nvarchar(20),@CourseName nvarchar(100),
      @Total int,@NewPlanId int;
    DECLARE plan_insert CURSOR LOCAL FAST_FORWARD FOR
      SELECT PlanKey,memberno,coachno,CourseName,TotalSessions FROM @PlanCatalog ORDER BY PlanKey;
    OPEN plan_insert;
    FETCH NEXT FROM plan_insert INTO @PlanKey,@MemberNo,@CoachNo,@CourseName,@Total;
    WHILE @@FETCH_STATUS=0
    BEGIN
      INSERT dbo.membercourse(coachid,memberid,courseid,purchasedate,totalsessions,remainingsessions,status)
        SELECT c.coachid,m.memberid,co.courseid,p.PurchaseDate,p.TotalSessions,p.TotalSessions,N''active''
        FROM @PlanCatalog p JOIN @CoachMap c ON c.coachno=p.coachno
        JOIN @MemberMap m ON m.memberno=p.memberno JOIN @CourseMap co ON co.CourseName=p.CourseName
        WHERE p.PlanKey=@PlanKey;
      SET @NewPlanId=CONVERT(int,SCOPE_IDENTITY());
      INSERT @PlanMap SELECT @PlanKey,@NewPlanId,@MemberNo,@CoachNo,@CourseName,@Total;
      FETCH NEXT FROM plan_insert INTO @PlanKey,@MemberNo,@CoachNo,@CourseName,@Total;
    END;
    CLOSE plan_insert; DEALLOCATE plan_insert;

    DECLARE @Event TABLE(EventCode nvarchar(100) PRIMARY KEY,SlotCode nvarchar(100) UNIQUE,PlanKey nvarchar(40),
      memberno nvarchar(20),ClassDate date,StartTime time(0),BookingStatus nvarchar(20),
      FixedAttendanceStatus nvarchar(20) NULL,ForcePending bit NOT NULL DEFAULT(0),Note nvarchar(100) NOT NULL);
    ;WITH A AS (SELECT n,memberno FROM @People WHERE n BETWEEN 1 AND 15),
    X AS (SELECT 1 AS SessionNo UNION ALL SELECT 2)
    INSERT @Event(EventCode,SlotCode,PlanKey,memberno,ClassDate,StartTime,BookingStatus,FixedAttendanceStatus,Note)
      SELECT N''H-A-''+a.memberno+N''-''+CONVERT(nvarchar(1),x.SessionNo),
        N''H-A-''+a.memberno+N''-''+CONVERT(nvarchar(1),x.SessionNo),
        CASE WHEN a.memberno=N''M007'' THEN N''A007_TRX'' ELSE N''A''+RIGHT(a.memberno,3)+N''_BASE'' END,
        a.memberno,
        CASE WHEN x.SessionNo=1 THEN DATEADD(day,a.n-1,CONVERT(date,''20260901'',112))
             ELSE DATEADD(day,a.n-1,CONVERT(date,''20260916'',112)) END,
        CASE WHEN x.SessionNo=1 THEN CONVERT(time(0),''09:00'') ELSE CONVERT(time(0),''11:00'') END,
        N''booked'',N''PRESENT'',N''展示用歷史預約''
      FROM A a CROSS JOIN X x;

    DECLARE @Extra TABLE(memberno nvarchar(20) PRIMARY KEY,Remaining int);
    INSERT @Extra VALUES(N''M005'',18),(N''M003'',7),(N''M004'',6),(N''M006'',9),(N''M011'',5),(N''M013'',5);
    DECLARE @ExtraMember nvarchar(20),@ExtraRemaining int,@ExtraDate date,@ExtraLoad int,@ExtraTime time(0),@ExtraPlan nvarchar(40),@ExtNo int=0;
    WHILE EXISTS(SELECT 1 FROM @Extra WHERE Remaining>0)
    BEGIN
      SELECT TOP(1) @ExtraMember=memberno,@ExtraRemaining=Remaining FROM @Extra WHERE Remaining>0 ORDER BY Remaining DESC,memberno;
      SET @ExtraDate=NULL; SET @ExtraLoad=NULL;
      SELECT TOP(1) @ExtraDate=d.D,@ExtraLoad=COALESCE(x.Cnt,0)
      FROM (SELECT DATEADD(day,v.n,CONVERT(date,''20260901'',112)) D FROM (VALUES
        (0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),
        (15),(16),(17),(18),(19),(20),(21),(22),(23),(24),(25),(26),(27),(28),(29)) v(n)) d
      OUTER APPLY (SELECT COUNT(*) Cnt FROM @Event e WHERE e.ClassDate=d.D AND e.StartTime IN(''13:00'',''15:00'')) x
      WHERE COALESCE(x.Cnt,0)<2 AND NOT EXISTS(SELECT 1 FROM @Event e WHERE e.memberno=@ExtraMember AND e.ClassDate=d.D)
      ORDER BY COALESCE(x.Cnt,0),d.D;
      IF @ExtraDate IS NULL THROW 51206,N''歷史加課排程容量不足；已回滾。'',1;
      SET @ExtraTime=CASE WHEN @ExtraLoad=0 THEN CONVERT(time(0),''13:00'') ELSE CONVERT(time(0),''15:00'') END;
      SET @ExtraPlan=N''A''+RIGHT(@ExtraMember,3)+N''_BASE'';
      SET @ExtNo+=1;
      INSERT @Event(EventCode,SlotCode,PlanKey,memberno,ClassDate,StartTime,BookingStatus,FixedAttendanceStatus,Note)
      VALUES(N''X-''+@ExtraMember+N''-''+CONVERT(nvarchar(8),@ExtraDate,112),
        N''X-''+@ExtraMember+N''-''+CONVERT(nvarchar(8),@ExtraDate,112),@ExtraPlan,@ExtraMember,@ExtraDate,@ExtraTime,
        N''booked'',N''PRESENT'',N''展示用歷史出席'');
      UPDATE @Extra SET Remaining=Remaining-1 WHERE memberno=@ExtraMember;
    END;

    DECLARE @OtherN int=16,@OtherMember nvarchar(20),@OtherCoach nvarchar(20),@OtherPrefix nvarchar(1),@OtherOrdinal int,@OtherStart time(0),@OtherPlan nvarchar(40),@HistDate date;
    WHILE @OtherN<=35
    BEGIN
      SELECT @OtherMember=memberno FROM @People WHERE n=@OtherN;
      SET @OtherCoach=CASE WHEN @OtherN<=20 THEN N''C002'' WHEN @OtherN<=25 THEN N''C003'' WHEN @OtherN<=30 THEN N''C004'' ELSE N''C005'' END;
      SET @OtherPrefix=CASE @OtherCoach WHEN N''C002'' THEN N''B'' WHEN N''C003'' THEN N''C'' WHEN N''C004'' THEN N''D'' ELSE N''E'' END;
      SET @OtherOrdinal=CASE WHEN @OtherN<=20 THEN @OtherN-15 WHEN @OtherN<=25 THEN @OtherN-20 WHEN @OtherN<=30 THEN @OtherN-25 ELSE @OtherN-30 END;
      SET @OtherStart=TIMEFROMPARTS(9+(@OtherOrdinal-1)*2,0,0,0,0);
      SET @OtherPlan=@OtherPrefix+RIGHT(@OtherMember,3)+N''_BASE'';
      DECLARE hist_dates CURSOR LOCAL FAST_FORWARD FOR SELECT CONVERT(date,v.d,112) FROM (VALUES(''20260905''),(''20260912''),(''20260919'')) v(d);
      OPEN hist_dates; FETCH NEXT FROM hist_dates INTO @HistDate;
      WHILE @@FETCH_STATUS=0
      BEGIN
        INSERT @Event(EventCode,SlotCode,PlanKey,memberno,ClassDate,StartTime,BookingStatus,FixedAttendanceStatus,Note)
        VALUES(N''H-''+@OtherMember+N''-''+CONVERT(nvarchar(8),@HistDate,112),
          N''H-''+@OtherMember+N''-''+CONVERT(nvarchar(8),@HistDate,112),@OtherPlan,@OtherMember,@HistDate,@OtherStart,
          N''booked'',N''PRESENT'',N''展示用歷史出席'');
        FETCH NEXT FROM hist_dates INTO @HistDate;
      END;
      CLOSE hist_dates; DEALLOCATE hist_dates;
      SET @OtherN+=1;
    END;

    DECLARE @AmyPool TABLE(pos int PRIMARY KEY,memberno nvarchar(20));
    INSERT @AmyPool VALUES(1,N''M001''),(2,N''M002''),(3,N''M003''),(4,N''M004''),(5,N''M006''),(6,N''M007''),
      (7,N''M008''),(8,N''M009''),(9,N''M010''),(10,N''M011''),(11,N''M012''),(12,N''M013''),(13,N''M014''),(14,N''M015'');
    DECLARE @Day date=CONVERT(date,''20261001'',112),@EndDay date=CONVERT(date,''20261029'',112),
      @DayIndex int=0,@SlotIndex int,@AmyMember nvarchar(20),@AmyPlan nvarchar(40),@AmyCourse nvarchar(100),
      @DailyStatus nvarchar(20),@PriorP int;
    WHILE @Day<=@EndDay
    BEGIN
      SET @SlotIndex=1;
      WHILE @SlotIndex<=4
      BEGIN
        SET @AmyMember=CASE
          WHEN @Day=CONVERT(date,''20261001'',112) THEN CASE @SlotIndex WHEN 1 THEN N''M006'' WHEN 2 THEN N''M011'' WHEN 3 THEN N''M013'' ELSE N''M001'' END
          WHEN @Day=CONVERT(date,''20261015'',112) THEN CASE @SlotIndex WHEN 1 THEN N''M007'' WHEN 2 THEN N''M006'' WHEN 3 THEN N''M011'' ELSE N''M002'' END
          WHEN @Day=CONVERT(date,''20261021'',112) THEN CASE @SlotIndex WHEN 1 THEN N''M001'' WHEN 2 THEN N''M006'' WHEN 3 THEN N''M008'' ELSE N''M010'' END
          WHEN @Day=CONVERT(date,''20261025'',112) THEN CASE @SlotIndex WHEN 1 THEN N''M013'' WHEN 2 THEN N''M006'' WHEN 3 THEN N''M008'' ELSE N''M010'' END
          ELSE (SELECT memberno FROM @AmyPool WHERE pos=((@DayIndex*4+@SlotIndex-1)%14)+1) END;
        SET @AmyPlan=CASE
          WHEN @AmyMember=N''M001'' AND @Day>=CONVERT(date,''20261020'',112) THEN N''A001_PURCHASE''
          WHEN @AmyMember=N''M007'' AND @Day=CONVERT(date,''20261015'',112) THEN N''A007_TRX''
          WHEN @AmyMember=N''M009'' AND @Day>=CONVERT(date,''20261020'',112) THEN N''A009_R2''
          WHEN @AmyMember=N''M009'' AND @Day>=CONVERT(date,''20261010'',112) THEN N''A009_R1''
          WHEN @AmyMember=N''M011'' AND @Day>=CONVERT(date,''20261010'',112) THEN N''A011_NEW''
          WHEN @AmyMember=N''M012'' AND @Day>=CONVERT(date,''20261010'',112) THEN N''A012_NEW''
          WHEN @AmyMember=N''M013'' AND @Day>=CONVERT(date,''20261020'',112) THEN N''A013_NEW''
          ELSE N''A''+RIGHT(@AmyMember,3)+N''_BASE'' END;
        SET @DailyStatus=CASE
          WHEN @AmyMember=N''M007'' AND @AmyPlan=N''A007_BASE'' THEN CASE WHEN @DayIndex%2=0 THEN N''LEAVE'' ELSE N''ABSENT'' END
          WHEN @AmyMember IN(N''M006'',N''M011'') AND @Day>CONVERT(date,''20261001'',112) THEN CASE WHEN @DayIndex%2=0 THEN N''LEAVE'' ELSE N''ABSENT'' END
          WHEN @AmyMember=N''M013'' AND @AmyPlan=N''A013_BASE'' AND @Day>CONVERT(date,''20261001'',112) THEN CASE WHEN @DayIndex%2=0 THEN N''LEAVE'' ELSE N''ABSENT'' END
          WHEN @AmyMember=N''M013'' AND @AmyPlan=N''A013_NEW'' AND @Day<CONVERT(date,''20261025'',112) THEN N''ABSENT''
          ELSE NULL END;
        SELECT @Total=TotalSessions FROM @PlanCatalog WHERE PlanKey=@AmyPlan;
        IF @DailyStatus IS NULL
        BEGIN
          SELECT @PriorP=COUNT(*) FROM @Event WHERE PlanKey=@AmyPlan AND FixedAttendanceStatus=N''PRESENT'';
          IF @AmyMember=N''M003'' AND @AmyPlan=N''A003_BASE'' AND @PriorP>=17 SET @DailyStatus=CASE WHEN @DayIndex%2=0 THEN N''LEAVE'' ELSE N''ABSENT'' END;
          ELSE IF @AmyMember=N''M004'' AND @AmyPlan=N''A004_BASE'' AND @PriorP>=16 SET @DailyStatus=CASE WHEN @DayIndex%2=0 THEN N''LEAVE'' ELSE N''ABSENT'' END;
          ELSE IF @AmyMember=N''M010'' AND @AmyPlan=N''A010_BASE'' AND @PriorP>=10 SET @DailyStatus=CASE WHEN @DayIndex%2=0 THEN N''LEAVE'' ELSE N''ABSENT'' END;
          ELSE IF @AmyMember=N''M013'' AND @AmyPlan=N''A013_BASE'' AND @Day=CONVERT(date,''20261001'',112) SET @DailyStatus=N''PRESENT'';
          ELSE IF @AmyMember=N''M013'' AND @AmyPlan=N''A013_NEW'' AND @Day=CONVERT(date,''20261025'',112) SET @DailyStatus=N''PRESENT'';
          ELSE IF @AmyMember=N''M007'' AND @AmyPlan=N''A007_TRX'' SET @DailyStatus=N''PRESENT'';
          ELSE IF @PriorP < @Total-5 SET @DailyStatus=N''PRESENT'';
          ELSE SET @DailyStatus=CASE WHEN @DayIndex%2=0 THEN N''LEAVE'' ELSE N''ABSENT'' END;
        END;
        INSERT @Event(EventCode,SlotCode,PlanKey,memberno,ClassDate,StartTime,BookingStatus,FixedAttendanceStatus,Note)
        VALUES(N''D-A-''+CONVERT(nvarchar(8),@Day,112)+N''-''+CONVERT(nvarchar(1),@SlotIndex),
          N''D-A-''+CONVERT(nvarchar(8),@Day,112)+N''-''+CONVERT(nvarchar(1),@SlotIndex),@AmyPlan,@AmyMember,@Day,
          TIMEFROMPARTS(9+(@SlotIndex-1)*2,0,0,0,0),N''booked'',@DailyStatus,N''展示用每日預約'');
        SET @SlotIndex+=1;
      END;
      SET @Day=DATEADD(day,1,@Day); SET @DayIndex+=1;
    END;

    DECLARE @FutureAmyPool TABLE(memberno nvarchar(20) PRIMARY KEY);
    INSERT @FutureAmyPool VALUES(N''M001''),(N''M002''),(N''M003''),(N''M004''),(N''M006''),(N''M007''),(N''M008''),
      (N''M009''),(N''M010''),(N''M011''),(N''M012''),(N''M013''),(N''M014''),(N''M015'');
    SET @Day=CONVERT(date,''20261030'',112); SET @EndDay=CONVERT(date,''20261113'',112);
    WHILE @Day<=@EndDay
    BEGIN
      SET @SlotIndex=1;
      WHILE @SlotIndex<=4
      BEGIN
        SET @AmyMember=NULL; SET @AmyPlan=NULL;
        SELECT TOP(1) @AmyMember=p.memberno,@AmyPlan=plan_choice.PlanKey
        FROM @FutureAmyPool p
        CROSS APPLY (VALUES(CASE
          WHEN p.memberno=N''M001'' AND @Day>=CONVERT(date,''20261020'',112) THEN N''A001_PURCHASE''
          WHEN p.memberno=N''M009'' AND @Day>=CONVERT(date,''20261020'',112) THEN N''A009_R2''
          WHEN p.memberno=N''M009'' AND @Day>=CONVERT(date,''20261010'',112) THEN N''A009_R1''
          WHEN p.memberno=N''M011'' AND @Day>=CONVERT(date,''20261010'',112) THEN N''A011_NEW''
          WHEN p.memberno=N''M012'' AND @Day>=CONVERT(date,''20261010'',112) THEN N''A012_NEW''
          WHEN p.memberno=N''M013'' AND @Day>=CONVERT(date,''20261020'',112) THEN N''A013_NEW''
          ELSE N''A''+RIGHT(p.memberno,3)+N''_BASE'' END)) plan_choice(PlanKey)
        JOIN @PlanCatalog pc ON pc.PlanKey=plan_choice.PlanKey
        OUTER APPLY (SELECT COUNT(*) AS PastPresentUpperBound
          FROM @Event e
          WHERE e.PlanKey=pc.PlanKey AND e.BookingStatus=N''booked''
            AND DATEADD(second,DATEDIFF(second,CONVERT(time(0),''00:00''),e.StartTime),CONVERT(datetime2(0),e.ClassDate))<=@SeedAsOf
            AND (e.FixedAttendanceStatus=N''PRESENT'' OR (e.FixedAttendanceStatus IS NULL AND e.ForcePending=0))) past_events
        OUTER APPLY (SELECT COUNT(*) AS FutureBookings
          FROM @Event e
          WHERE e.PlanKey=pc.PlanKey AND e.BookingStatus=N''booked''
            AND DATEADD(second,DATEDIFF(second,CONVERT(time(0),''00:00''),e.StartTime),CONVERT(datetime2(0),e.ClassDate))>@SeedAsOf) future_events
        WHERE NOT EXISTS(SELECT 1 FROM @Event same_day WHERE same_day.memberno=p.memberno AND same_day.ClassDate=@Day)
          AND pc.TotalSessions-past_events.PastPresentUpperBound-future_events.FutureBookings>2
        ORDER BY future_events.FutureBookings,
          pc.TotalSessions-past_events.PastPresentUpperBound-future_events.FutureBookings DESC,p.memberno;
        IF @AmyMember IS NULL
            THROW 51222,N''AMY未來預約分配容量不足，無法保留每方案剩堂空間；交易將回滾。'',1;
        SET @DailyStatus=NULL;
        IF @Day=@SeedDate AND @SlotIndex=4 SET @DailyStatus=N''PENDING'';
        ELSE IF DATEADD(second,DATEDIFF(second,CONVERT(time(0),''00:00''),TIMEFROMPARTS(9+(@SlotIndex-1)*2,0,0,0,0)),CONVERT(datetime2(0),@Day))<@SeedAsOf
        BEGIN
          IF @AmyMember=N''M007'' AND @AmyPlan=N''A007_BASE'' SET @DailyStatus=N''LEAVE'';
          ELSE IF @AmyMember IN(N''M006'',N''M011'') AND @Day>CONVERT(date,''20261001'',112) SET @DailyStatus=N''ABSENT'';
          ELSE IF @AmyMember=N''M013'' AND @AmyPlan=N''A013_BASE'' AND @Day>CONVERT(date,''20261001'',112) SET @DailyStatus=N''ABSENT'';
          ELSE IF @AmyMember=N''M013'' AND @AmyPlan=N''A013_NEW'' AND @Day>=CONVERT(date,''20261025'',112) SET @DailyStatus=N''PRESENT'';
          ELSE IF @AmyMember=N''M003'' AND @AmyPlan=N''A003_BASE'' AND (SELECT COUNT(*) FROM @Event WHERE PlanKey=@AmyPlan AND FixedAttendanceStatus=N''PRESENT'')>=17 SET @DailyStatus=N''ABSENT'';
          ELSE IF @AmyMember=N''M004'' AND @AmyPlan=N''A004_BASE'' AND (SELECT COUNT(*) FROM @Event WHERE PlanKey=@AmyPlan AND FixedAttendanceStatus=N''PRESENT'')>=16 SET @DailyStatus=N''ABSENT'';
          ELSE IF @AmyMember=N''M010'' AND @AmyPlan=N''A010_BASE'' AND (SELECT COUNT(*) FROM @Event WHERE PlanKey=@AmyPlan AND FixedAttendanceStatus=N''PRESENT'')>=10 SET @DailyStatus=N''ABSENT'';
          ELSE IF (SELECT COUNT(*) FROM @Event WHERE PlanKey=@AmyPlan AND FixedAttendanceStatus=N''PRESENT'') < (SELECT TotalSessions-5 FROM @PlanCatalog WHERE PlanKey=@AmyPlan) SET @DailyStatus=N''PRESENT'';
          ELSE SET @DailyStatus=N''LEAVE'';
        END;
        INSERT @Event(EventCode,SlotCode,PlanKey,memberno,ClassDate,StartTime,BookingStatus,FixedAttendanceStatus,ForcePending,Note)
        VALUES(N''F-A-''+CONVERT(nvarchar(8),@Day,112)+N''-''+CONVERT(nvarchar(1),@SlotIndex),
          N''F-A-''+CONVERT(nvarchar(8),@Day,112)+N''-''+CONVERT(nvarchar(1),@SlotIndex),@AmyPlan,@AmyMember,@Day,
          TIMEFROMPARTS(9+(@SlotIndex-1)*2,0,0,0,0),N''booked'',@DailyStatus,
          CASE WHEN @Day=@SeedDate AND @SlotIndex=4 THEN 1 ELSE 0 END,N''展示用班表預約'');
        SET @SlotIndex+=1;
      END;
      SET @Day=DATEADD(day,1,@Day);
    END;

    DECLARE @CoachLoop nvarchar(20),@CoachBase int,@CoachPrefix nvarchar(1),@CoachIdx int,@RosterN int,@RosterMember nvarchar(20),@RosterPlan nvarchar(40),@OtherSlot int,@CoachIter int;
    SET @Day=CONVERT(date,''20261030'',112); SET @EndDay=CONVERT(date,''20261113'',112); SET @DayIndex=0;
    WHILE @Day<=@EndDay
    BEGIN
      SET @CoachIter=2;
      WHILE @CoachIter<=5
      BEGIN
        SET @CoachLoop=N''C00''+CONVERT(nvarchar(1),@CoachIter);
        SET @CoachBase=CASE @CoachLoop WHEN N''C002'' THEN 16 WHEN N''C003'' THEN 21 WHEN N''C004'' THEN 26 ELSE 31 END;
        SET @CoachPrefix=CASE @CoachLoop WHEN N''C002'' THEN N''B'' WHEN N''C003'' THEN N''C'' WHEN N''C004'' THEN N''D'' ELSE N''E'' END;
        SET @OtherSlot=1;
        WHILE @OtherSlot<=2
        BEGIN
          SET @RosterN=((@DayIndex*2+@OtherSlot-1)%5)+1;
          SET @RosterMember=(SELECT memberno FROM @People WHERE n=@CoachBase+@RosterN-1);
          SET @RosterPlan=@CoachPrefix+RIGHT(@RosterMember,3)+N''_BASE'';
          SET @DailyStatus=NULL;
          IF @Day<@SeedDate OR (@Day=@SeedDate AND TIMEFROMPARTS(9+(@OtherSlot-1)*2,0,0,0,0)<=CONVERT(time(0),@SeedAsOf))
              SET @DailyStatus=N''PRESENT'';
          INSERT @Event(EventCode,SlotCode,PlanKey,memberno,ClassDate,StartTime,BookingStatus,FixedAttendanceStatus,Note)
          VALUES(N''F-''+@CoachLoop+N''-''+CONVERT(nvarchar(8),@Day,112)+N''-''+CONVERT(nvarchar(1),@OtherSlot),
            N''F-''+@CoachLoop+N''-''+CONVERT(nvarchar(8),@Day,112)+N''-''+CONVERT(nvarchar(1),@OtherSlot),@RosterPlan,@RosterMember,@Day,
            TIMEFROMPARTS(9+(@OtherSlot-1)*2,0,0,0,0),N''booked'',@DailyStatus,N''展示用班表預約'');
          SET @OtherSlot+=1;
        END;
        SET @CoachIter+=1;
      END;
      SET @Day=DATEADD(day,1,@Day); SET @DayIndex+=1;
    END;

    INSERT @Event(EventCode,SlotCode,PlanKey,memberno,ClassDate,StartTime,BookingStatus,Note)
      VALUES(N''CANCEL-A-20261102'',N''OP-A-20261102-1700'',N''A003_BASE'',N''M003'',''20261102'',''17:00'',N''cancelled'',N''取消後可重新預約展示'');

    DECLARE @Slot TABLE(SlotCode nvarchar(100) PRIMARY KEY,coachno nvarchar(20),CourseName nvarchar(100),ClassDate date,
      StartTime time(0),EndTime time(0),Classroom nvarchar(50),Status nvarchar(20));
    INSERT @Slot(SlotCode,coachno,CourseName,ClassDate,StartTime,EndTime,Classroom,Status)
      SELECT e.SlotCode,p.coachno,p.CourseName,e.ClassDate,e.StartTime,DATEADD(minute,60,e.StartTime),
        N''Demo Room ''+c.FullName,N''open''
      FROM @Event e JOIN @PlanCatalog p ON p.PlanKey=e.PlanKey JOIN @Coaches c ON c.coachno=p.coachno;
    DECLARE @PairCoach nvarchar(20),@C1 nvarchar(100),@C2 nvarchar(100),@C3 nvarchar(100),@OpenIdx int,@OpenTime time(0),@OpenCourse nvarchar(100),@Room nvarchar(50);
    SET @Day=CONVERT(date,''20261030'',112); SET @EndDay=CONVERT(date,''20261213'',112);
    WHILE @Day<=@EndDay
    BEGIN
      DECLARE pair_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT coachno,Course1,Course2,Course3 FROM @PairCatalog ORDER BY coachno;
      OPEN pair_cursor; FETCH NEXT FROM pair_cursor INTO @PairCoach,@C1,@C2,@C3;
      WHILE @@FETCH_STATUS=0
      BEGIN
        IF @PairCoach=N''C001''
        BEGIN
          IF NOT EXISTS(SELECT 1 FROM @Slot WHERE SlotCode=N''OP-A-''+CONVERT(nvarchar(8),@Day,112)+N''-1700'')
            INSERT @Slot VALUES(N''OP-A-''+CONVERT(nvarchar(8),@Day,112)+N''-1700'',@PairCoach,@C1,@Day,''17:00'',''18:00'',N''Demo Room AMY'',N''open'');
          SET @OpenCourse=CASE WHEN DATEDIFF(day,CONVERT(date,''20261030'',112),@Day)%2=0 THEN @C2 ELSE @C3 END;
          INSERT @Slot VALUES(N''OP-A-''+CONVERT(nvarchar(8),@Day,112)+N''-1900'',@PairCoach,@OpenCourse,@Day,''19:00'',''20:00'',N''Demo Room AMY'',N''open'');
        END
        ELSE
        BEGIN
          SET @OpenIdx=13; SET @Room=N''Demo Room ''+CASE @PairCoach WHEN N''C002'' THEN N''BEN'' WHEN N''C003'' THEN N''CHRIS'' WHEN N''C004'' THEN N''DAVID'' ELSE N''ERIC'' END;
          WHILE @OpenIdx<=19
          BEGIN
            SET @OpenTime=TIMEFROMPARTS(@OpenIdx,0,0,0,0);
            SET @OpenCourse=CASE WHEN @C2 IS NULL OR @OpenIdx IN(13,17) THEN @C1 ELSE @C2 END;
            INSERT @Slot VALUES(N''OP-''+@PairCoach+N''-''+CONVERT(nvarchar(8),@Day,112)+N''-''+RIGHT(N''0''+CONVERT(nvarchar(2),@OpenIdx),2)+N''00'',
              @PairCoach,@OpenCourse,@Day,@OpenTime,DATEADD(minute,60,@OpenTime),@Room,N''open'');
            SET @OpenIdx+=2;
          END;
        END;
        FETCH NEXT FROM pair_cursor INTO @PairCoach,@C1,@C2,@C3;
      END;
      CLOSE pair_cursor; DEALLOCATE pair_cursor;
      SET @Day=DATEADD(day,1,@Day);
    END;
    INSERT @Slot VALUES(N''CL-A-20261105-1800'',N''C001'',N''初階重訓'',''20261105'',''18:00'',''19:00'',N''Demo Room AMY'',N''closed''),
      (N''CL-B-20261105-1800'',N''C002'',N''筋膜放鬆'',''20261105'',''18:00'',''19:00'',N''Demo Room BEN'',N''closed''),
      (N''CL-C-20261105-1800'',N''C003'',N''中階重訓'',''20261105'',''18:00'',''19:00'',N''Demo Room CHRIS'',N''closed''),
      (N''CL-D-20261105-1800'',N''C004'',N''初階重訓'',''20261105'',''18:00'',''19:00'',N''Demo Room DAVID'',N''closed''),
      (N''CL-E-20261105-1800'',N''C005'',N''高階重訓'',''20261105'',''18:00'',''19:00'',N''Demo Room ERIC'',N''closed'');

    DECLARE @ScheduleMap TABLE(SlotCode nvarchar(100) PRIMARY KEY,scheduleid int NOT NULL);
    DECLARE @SlotCode nvarchar(100),@SlotDate date,@SlotStart time(0),@SlotEnd time(0),@SlotRoom nvarchar(50),@SlotStatus nvarchar(20),@ScheduleId int;
    DECLARE slot_insert CURSOR LOCAL FAST_FORWARD FOR SELECT SlotCode,coachno,CourseName,ClassDate,StartTime,EndTime,Classroom,Status FROM @Slot ORDER BY ClassDate,StartTime,coachno;
    OPEN slot_insert;
    DECLARE @SlotCoach nvarchar(20),@SlotCourse nvarchar(100);
    FETCH NEXT FROM slot_insert INTO @SlotCode,@SlotCoach,@SlotCourse,@SlotDate,@SlotStart,@SlotEnd,@SlotRoom,@SlotStatus;
    WHILE @@FETCH_STATUS=0
    BEGIN
      INSERT dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status)
        SELECT c.coachid,co.courseid,@SlotDate,@SlotStart,@SlotEnd,@SlotRoom,@SlotStatus
        FROM @CoachMap c CROSS JOIN @CourseMap co WHERE c.coachno=@SlotCoach AND co.CourseName=@SlotCourse;
      SET @ScheduleId=CONVERT(int,SCOPE_IDENTITY());
      INSERT @ScheduleMap VALUES(@SlotCode,@ScheduleId);
      FETCH NEXT FROM slot_insert INTO @SlotCode,@SlotCoach,@SlotCourse,@SlotDate,@SlotStart,@SlotEnd,@SlotRoom,@SlotStatus;
    END;
    CLOSE slot_insert; DEALLOCATE slot_insert;

    DECLARE event_cursor CURSOR LOCAL FAST_FORWARD FOR
      SELECT e.EventCode,e.SlotCode,e.PlanKey,e.memberno,e.ClassDate,e.StartTime,e.BookingStatus,e.FixedAttendanceStatus,e.ForcePending,e.Note
      FROM @Event e ORDER BY e.ClassDate,e.StartTime,e.EventCode;
    DECLARE @EventCode nvarchar(100),@EventPlan nvarchar(40),@EventMember nvarchar(20),@EventDate date,@EventTime time(0),
      @BookingStatus nvarchar(20),@AttendanceStatus nvarchar(20),@ForcePending bit,@EventNote nvarchar(100),
      @PlanId int,@MemberId int,@EventCoach nvarchar(20),@EventCourse nvarchar(100),@PresentSoFar int,@PlanTotal int,@BookingId int,@Checkin datetime2(0);
    OPEN event_cursor;
    FETCH NEXT FROM event_cursor INTO @EventCode,@SlotCode,@EventPlan,@EventMember,@EventDate,@EventTime,@BookingStatus,@AttendanceStatus,@ForcePending,@EventNote;
    WHILE @@FETCH_STATUS=0
    BEGIN
      SELECT @PlanId=pm.membercourseid,@EventCoach=pm.coachno,@EventCourse=pm.CourseName,@PlanTotal=pm.TotalSessions
      FROM @PlanMap pm WHERE pm.PlanKey=@EventPlan;
      SELECT @MemberId=memberid FROM @MemberMap WHERE memberno=@EventMember;
      SELECT @ScheduleId=scheduleid FROM @ScheduleMap WHERE SlotCode=@SlotCode;
      INSERT dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime)
        VALUES(@PlanId,@ScheduleId,
          CASE WHEN DATEADD(second,DATEDIFF(second,CONVERT(time(0),''00:00''),@EventTime),CONVERT(datetime2(0),@EventDate))>@SeedAsOf
               THEN @SeedAsOf ELSE DATEADD(minute,-15,DATEADD(second,DATEDIFF(second,CONVERT(time(0),''00:00''),@EventTime),CONVERT(datetime2(0),@EventDate))) END,
          @BookingStatus,@EventNote,@SeedAsOf);
      SET @BookingId=CONVERT(int,SCOPE_IDENTITY());
      IF @BookingStatus=N''booked''
      BEGIN
        IF @ForcePending=1 SET @AttendanceStatus=N''PENDING'';
        ELSE IF @AttendanceStatus IS NULL AND DATEADD(second,DATEDIFF(second,CONVERT(time(0),''00:00''),@EventTime),CONVERT(datetime2(0),@EventDate))<=@SeedAsOf
        BEGIN
          SELECT @PresentSoFar=COUNT(*) FROM @Event e WHERE e.PlanKey=@EventPlan AND e.FixedAttendanceStatus=N''PRESENT''
            AND (e.ClassDate<@EventDate OR (e.ClassDate=@EventDate AND e.StartTime<@EventTime));
          IF @EventCoach=N''C001'' AND @EventMember=N''M007'' AND @EventPlan=N''A007_BASE'' SET @AttendanceStatus=CASE WHEN DATEPART(day,@EventDate)%2=0 THEN N''LEAVE'' ELSE N''ABSENT'' END;
          ELSE IF @EventCoach=N''C001'' AND @EventMember IN(N''M006'',N''M011'') AND @EventDate>CONVERT(date,''20261001'',112) SET @AttendanceStatus=CASE WHEN DATEPART(day,@EventDate)%2=0 THEN N''LEAVE'' ELSE N''ABSENT'' END;
          ELSE IF @EventCoach=N''C001'' AND @EventMember=N''M013'' AND @EventPlan=N''A013_BASE'' AND @EventDate>CONVERT(date,''20261001'',112) SET @AttendanceStatus=N''ABSENT'';
          ELSE IF @EventCoach=N''C001'' AND @EventMember=N''M013'' AND @EventPlan=N''A013_NEW'' AND @EventDate<CONVERT(date,''20261025'',112) SET @AttendanceStatus=N''ABSENT'';
          ELSE IF @EventCoach=N''C001'' AND @EventMember=N''M003'' AND @EventPlan=N''A003_BASE'' AND @PresentSoFar>=17 SET @AttendanceStatus=N''ABSENT'';
          ELSE IF @EventCoach=N''C001'' AND @EventMember=N''M004'' AND @EventPlan=N''A004_BASE'' AND @PresentSoFar>=16 SET @AttendanceStatus=N''ABSENT'';
          ELSE IF @EventCoach=N''C001'' AND @EventMember=N''M010'' AND @EventPlan=N''A010_BASE'' AND @PresentSoFar>=10 SET @AttendanceStatus=N''ABSENT'';
          ELSE IF @PresentSoFar<@PlanTotal-5 SET @AttendanceStatus=N''PRESENT'';
          ELSE SET @AttendanceStatus=N''LEAVE'';
        END;
        IF @AttendanceStatus IS NOT NULL
        BEGIN
          UPDATE @Event SET FixedAttendanceStatus=@AttendanceStatus WHERE EventCode=@EventCode;
          SET @Checkin=CASE WHEN @AttendanceStatus=N''PRESENT''
            THEN CASE WHEN DATEADD(minute,5,DATEADD(second,DATEDIFF(second,CONVERT(time(0),''00:00''),@EventTime),CONVERT(datetime2(0),@EventDate)))<=@SeedAsOf
                THEN DATEADD(minute,5,DATEADD(second,DATEDIFF(second,CONVERT(time(0),''00:00''),@EventTime),CONVERT(datetime2(0),@EventDate))) ELSE @SeedAsOf END
            ELSE NULL END;
          INSERT dbo.attendance(updatetime,bookingid,checkintime,attendancestatus,workoutfocus,note)
          VALUES(@SeedAsOf,@BookingId,@Checkin,@AttendanceStatus,
            CASE WHEN @AttendanceStatus=N''PRESENT'' THEN CASE WHEN DATEPART(day,@EventDate)%2=0 THEN N''核心與肌力'' ELSE N''下肢肌力'' END ELSE NULL END,
            CASE WHEN @AttendanceStatus=N''PENDING'' THEN N''待點名展示資料'' WHEN @AttendanceStatus=N''PRESENT'' THEN N''展示用出席紀錄'' ELSE N''展示用請假／缺席備註'' END);
        END;
      END;
      FETCH NEXT FROM event_cursor INTO @EventCode,@SlotCode,@EventPlan,@EventMember,@EventDate,@EventTime,@BookingStatus,@AttendanceStatus,@ForcePending,@EventNote;
    END;
    CLOSE event_cursor; DEALLOCATE event_cursor;

    ;WITH P AS (
      SELECT b.membercourseid,COUNT(*) AS PresentCount
      FROM dbo.booking b JOIN dbo.attendance a ON a.bookingid=b.bookingid
      WHERE b.bookingstatus=N''booked'' AND a.attendancestatus=N''PRESENT''
      GROUP BY b.membercourseid
    )
    UPDATE mc SET remainingsessions=mc.totalsessions-COALESCE(p.PresentCount,0),
      status=CASE WHEN mc.totalsessions-COALESCE(p.PresentCount,0)=0 THEN N''usedup'' ELSE N''active'' END
    FROM dbo.membercourse mc JOIN @PlanMap pm ON pm.membercourseid=mc.membercourseid
    LEFT JOIN P p ON p.membercourseid=mc.membercourseid;

    ;WITH Ranked AS (
      SELECT a.attendanceid,m.memberid,cs.classdate,
        ROW_NUMBER() OVER(PARTITION BY m.memberid ORDER BY cs.classdate,b.bookingid) seq
      FROM dbo.attendance a JOIN dbo.booking b ON b.bookingid=a.bookingid
      JOIN dbo.classschedule cs ON cs.scheduleid=b.scheduleid
      JOIN dbo.membercourse mc ON mc.membercourseid=b.membercourseid
      JOIN @MemberMap m ON m.memberid=mc.memberid
      WHERE a.attendancestatus=N''PRESENT'' AND b.bookingstatus=N''booked''
    )
    INSERT dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass)
      SELECT attendanceid,memberid,classdate,
        CONVERT(decimal(5,2),65.00+(memberid%17)*0.73-(seq-1)*0.12),
        CONVERT(decimal(4,1),20.0+(memberid%11)*0.6-(seq-1)*0.2),
        CONVERT(decimal(4,1),25.0+(memberid%10)*0.7+(seq-1)*0.1)
      FROM Ranked;

    INSERT dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note)
      SELECT src.membercourseid,dst.membercourseid,@SeedAsOf,dst.TotalSessions,v.Amount,v.PaymentMethod,v.Note
      FROM (VALUES
        (N''A009_BASE'',N''A009_R1'',24000,N''cash'',N''同課續約第一筆''),
        (N''A009_BASE'',N''A009_R2'',28000,N''transfer'',N''同來源方案再次續約''),
        (N''A011_BASE'',N''A011_NEW'',21000,N''card'',N''同課續約''),
        (N''A012_BASE'',N''A012_NEW'',33000,N''transfer'',N''由TRX加購同教練其他課程''),
        (N''A013_BASE'',N''A013_NEW'',26000,N''cash'',N''同課續約'')) v(SourceKey,NewKey,Amount,PaymentMethod,Note)
      JOIN @PlanMap src ON src.PlanKey=v.SourceKey JOIN @PlanMap dst ON dst.PlanKey=v.NewKey;

    INSERT dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate)
      SELECT pm.membercourseid,c.coachid,N''AGREED'',N''PHONE'',N''已聯繫，學員考慮續約；此紀錄不代表已建立續約。'',DATEADD(day,-2,@SeedAsOf)
      FROM @PlanMap pm JOIN @CoachMap c ON c.coachno=pm.coachno WHERE pm.PlanKey=N''A008_BASE'';
    INSERT dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate)
      SELECT pm.membercourseid,c.coachid,N''DECLINED'',N''MESSAGE'',N''學員目前暫不續約，保留原方案上課權利。'',DATEADD(day,-1,@SeedAsOf)
      FROM @PlanMap pm JOIN @CoachMap c ON c.coachno=pm.coachno WHERE pm.PlanKey=N''A010_BASE'';
    ;WITH F AS (SELECT n FROM (VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11)) v(n))
    INSERT dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate)
      SELECT pm.membercourseid,c.coachid,
        CASE f.n%4 WHEN 0 THEN N''AGREED'' WHEN 1 THEN N''CONSIDERING'' WHEN 2 THEN N''NO_RESPONSE'' ELSE N''DECLINED'' END,
        CASE f.n%4 WHEN 0 THEN N''PHONE'' WHEN 1 THEN N''MESSAGE'' WHEN 2 THEN N''IN_PERSON'' ELSE N''OTHER'' END,
        CASE f.n WHEN 1 THEN N''回訪：確認近期訓練安排與續課意願。'' WHEN 2 THEN N''電話聯繫：學員希望先完成本期課程。''
          WHEN 3 THEN N''現場交流：討論下一階段訓練目標。'' WHEN 4 THEN N''訊息追蹤：已傳送課程安排資訊。''
          WHEN 5 THEN N''回訪：學員詢問不同課程的差異。'' WHEN 6 THEN N''電話聯繫：確認可聯絡時段。''
          WHEN 7 THEN N''現場交流：回顧訓練進度。'' WHEN 8 THEN N''訊息追蹤：等待學員回覆。''
          WHEN 9 THEN N''回訪：討論剩餘堂數與上課頻率。'' WHEN 10 THEN N''電話聯繫：確認近期目標。''
          ELSE N''後續追蹤：記錄本次聯繫結果。'' END,
        CASE WHEN f.n IN(1,2) THEN DATEADD(day,-3,@SeedAsOf) ELSE DATEADD(day,-f.n,@SeedAsOf) END
      FROM F f CROSS JOIN @PlanMap pm JOIN @CoachMap c ON c.coachno=pm.coachno WHERE pm.PlanKey=N''A015_BASE'';

    IF (SELECT COUNT(*) FROM dbo.useraccount)<>41 OR (SELECT COUNT(*) FROM dbo.member)<>35
       OR (SELECT COUNT(*) FROM dbo.coach)<>5 OR (SELECT COUNT(*) FROM dbo.course)<>5
       OR (SELECT COUNT(*) FROM dbo.coachcourse)<>10 OR (SELECT COUNT(*) FROM dbo.membercourse)<>42
        THROW 51207,N''核心資料筆數不符；交易將回滾。'',1;
    IF EXISTS (
      SELECT expected.coachno,expected.MemberCount,COUNT(DISTINCT mc.memberid) actual
      FROM (VALUES(N''C001'',15),(N''C002'',5),(N''C003'',5),(N''C004'',5),(N''C005'',5)) expected(coachno,MemberCount)
      JOIN @CoachMap c ON c.coachno=expected.coachno JOIN dbo.membercourse mc ON mc.coachid=c.coachid
      GROUP BY expected.coachno,expected.MemberCount HAVING COUNT(DISTINCT mc.memberid)<>expected.MemberCount)
        THROW 51208,N''教練不同會員人數不符；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM dbo.membercourse WHERE totalsessions NOT IN(20,24,30)
        OR remainingsessions<>totalsessions-(SELECT COUNT(*) FROM dbo.booking b JOIN dbo.attendance a ON a.bookingid=b.bookingid
          WHERE b.membercourseid=membercourse.membercourseid AND b.bookingstatus=N''booked'' AND a.attendancestatus=N''PRESENT'')
        OR status<>CASE WHEN remainingsessions=0 THEN N''usedup'' ELSE N''active'' END)
        THROW 51209,N''方案堂數／狀態與 PRESENT 不一致；交易將回滾。'',1;
    DECLARE @ScheduleDays TABLE(D date PRIMARY KEY);
    DECLARE @ScheduleDay date=CONVERT(date,''20261030'',112);
    WHILE @ScheduleDay<=CONVERT(date,''20261213'',112)
    BEGIN
      INSERT @ScheduleDays VALUES(@ScheduleDay);
      SET @ScheduleDay=DATEADD(day,1,@ScheduleDay);
    END;
    DECLARE @DisplayDays TABLE(D date PRIMARY KEY);
    DECLARE @DisplayDay date=CONVERT(date,''20261001'',112);
    WHILE @DisplayDay<=CONVERT(date,''20261113'',112)
    BEGIN
      INSERT @DisplayDays VALUES(@DisplayDay);
      SET @DisplayDay=DATEADD(day,1,@DisplayDay);
    END;
    IF EXISTS (SELECT 1 FROM @DisplayDays d WHERE
      (SELECT COUNT(DISTINCT mc.memberid) FROM dbo.booking b
       JOIN dbo.classschedule cs ON cs.scheduleid=b.scheduleid
       JOIN dbo.membercourse mc ON mc.membercourseid=b.membercourseid
       JOIN @CoachMap c ON c.coachid=mc.coachid
       WHERE c.coachno=N''C001'' AND b.bookingstatus=N''booked'' AND cs.classdate=d.D)<4)
        THROW 51210,N''AMY每日有效預約不足四位不同會員（含零預約日期）；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM dbo.inbodyrecords i JOIN dbo.attendance a ON a.attendanceid=i.attendanceid
        JOIN dbo.booking b ON b.bookingid=a.bookingid JOIN dbo.membercourse mc ON mc.membercourseid=b.membercourseid
        WHERE a.attendancestatus<>N''PRESENT'' OR i.memberid<>mc.memberid OR i.recorddate<>(SELECT classdate FROM dbo.classschedule WHERE scheduleid=b.scheduleid))
        THROW 51211,N''InBody 與 PRESENT／會員／上課日期關聯不一致；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM dbo.classschedule a JOIN dbo.classschedule b ON a.scheduleid<b.scheduleid
        AND a.classdate=b.classdate AND (a.coachid=b.coachid OR a.classroom=b.classroom)
        AND a.starttime<b.endtime AND b.starttime<a.endtime)
        THROW 51212,N''教練或教室課表時段重疊；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM dbo.booking a JOIN dbo.classschedule sa ON sa.scheduleid=a.scheduleid
        JOIN dbo.membercourse ma ON ma.membercourseid=a.membercourseid
        JOIN dbo.booking b ON a.bookingid<b.bookingid AND b.bookingstatus=N''booked''
        JOIN dbo.classschedule sb ON sb.scheduleid=b.scheduleid JOIN dbo.membercourse mb ON mb.membercourseid=b.membercourseid
        WHERE a.bookingstatus=N''booked'' AND sa.classdate=sb.classdate AND ma.memberid=mb.memberid
          AND sa.starttime<sb.endtime AND sb.starttime<sa.endtime)
        THROW 51213,N''同一會員存在重疊有效預約；交易將回滾。'',1;
    -- FIX 51219: filter to future bookings BEFORE grouping.
    -- A used-up plan with only historical bookings has no future capacity requirement.
    DECLARE @Capacity TABLE(PlanKey nvarchar(40),membercourseid int,MemberName nvarchar(50),
        RemainingSessions int,FutureBookings int,RequiredSessions int,Shortfall int);
    INSERT @Capacity
      SELECT pm.PlanKey,mc.membercourseid,m.name,mc.remainingsessions,COUNT(*),COUNT(*)+1,
        COUNT(*)+1-mc.remainingsessions
      FROM dbo.booking b JOIN dbo.classschedule cs ON cs.scheduleid=b.scheduleid
      JOIN dbo.membercourse mc ON mc.membercourseid=b.membercourseid
      JOIN dbo.member m ON m.memberid=mc.memberid JOIN @PlanMap pm ON pm.membercourseid=mc.membercourseid
      WHERE b.bookingstatus=N''booked''
        AND DATEADD(second,DATEDIFF(second,CONVERT(time(0),''00:00''),cs.starttime),
                    CONVERT(datetime2(0),cs.classdate))>@SeedAsOf
      GROUP BY pm.PlanKey,mc.membercourseid,m.name,mc.remainingsessions;
    IF EXISTS (SELECT 1 FROM @Capacity WHERE Shortfall>0)
    BEGIN
      SELECT N''51219_CAPACITY_DETAIL'' AS diagnostic,* FROM @Capacity WHERE Shortfall>0;
      THROW 51219,N''有未來有效預約的方案剩堂不足以支應預約並保留一堂空間；交易將回滾。'',1;
    END;
    IF EXISTS (SELECT 1 FROM dbo.booking b JOIN dbo.classschedule cs ON cs.scheduleid=b.scheduleid
        JOIN dbo.attendance a ON a.bookingid=b.bookingid
        WHERE DATEADD(second,DATEDIFF(second,CONVERT(time(0),''00:00''),cs.starttime),CONVERT(datetime2(0),cs.classdate))>@SeedAsOf
          AND a.attendancestatus<>N''PENDING'')
        THROW 51220,N''尚未開始的課程已有非 PENDING 出席結果；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM dbo.booking b JOIN dbo.classschedule cs ON cs.scheduleid=b.scheduleid
        JOIN dbo.attendance a ON a.bookingid=b.bookingid
        WHERE b.bookingstatus=N''cancelled'')
        THROW 51221,N''取消預約不應有 Attendance；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM dbo.booking b JOIN dbo.classschedule cs ON cs.scheduleid=b.scheduleid
        JOIN dbo.attendance a ON a.bookingid=b.bookingid
        WHERE a.attendancestatus=N''PRESENT'' AND NOT EXISTS(SELECT 1 FROM dbo.inbodyrecords i WHERE i.attendanceid=a.attendanceid))
        THROW 51222,N''PRESENT 展示資料未建立量測；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM @People p LEFT JOIN dbo.inbodyrecords i ON i.memberid=(SELECT memberid FROM @MemberMap WHERE memberno=p.memberno)
        JOIN dbo.membercourse mc ON mc.memberid=(SELECT memberid FROM @MemberMap WHERE memberno=p.memberno)
        WHERE p.n<=15 GROUP BY p.memberno HAVING COUNT(DISTINCT i.inbodyid)<3)
        THROW 51214,N''Amy 會員未達每人三筆 InBody；交易將回滾。'',1;
    IF (SELECT COUNT(DISTINCT i.recorddate) FROM dbo.inbodyrecords i
        JOIN dbo.attendance a ON a.attendanceid=i.attendanceid
        JOIN dbo.booking b ON b.bookingid=a.bookingid
        JOIN @PlanMap p ON p.membercourseid=b.membercourseid
        WHERE p.PlanKey=N''A002_BASE'')<6
        THROW 51215,N''M002同一方案InBody未達六個不同上課日；交易將回滾。'',1;
    IF (SELECT COUNT(*) FROM dbo.followup f JOIN @PlanMap p ON p.membercourseid=f.membercourseid WHERE p.PlanKey=N''A015_BASE'')<11
        THROW 51216,N''A015 同方案跟進紀錄未達十一筆；交易將回滾。'',1;
    IF (SELECT COUNT(*) FROM dbo.renewal)<>5
       OR NOT EXISTS(SELECT 1 FROM @PlanMap oldp JOIN dbo.renewal r ON r.membercourseid=oldp.membercourseid
            JOIN @PlanMap newp ON newp.membercourseid=r.newmembercourseid
            WHERE oldp.PlanKey=N''A012_BASE'' AND newp.PlanKey=N''A012_NEW'' AND oldp.CourseName<>newp.CourseName)
       OR NOT EXISTS(SELECT 1 FROM @PlanMap oldp JOIN dbo.renewal r ON r.membercourseid=oldp.membercourseid
            JOIN @PlanMap newp ON newp.membercourseid=r.newmembercourseid
            WHERE oldp.PlanKey=N''A009_BASE'' AND newp.PlanKey=N''A009_R1'')
        THROW 51217,N''續約來源／新方案關聯不符；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM @CoachMap cm CROSS JOIN @ScheduleDays d
      WHERE (SELECT COUNT(*) FROM dbo.classschedule cs
        WHERE cs.coachid=cm.coachid AND cs.classdate=d.D AND cs.status=N''open''
          AND NOT EXISTS(SELECT 1 FROM dbo.booking b WHERE b.scheduleid=cs.scheduleid AND b.bookingstatus=N''booked''))<2)
         THROW 51218,N''2026-10-30 至 2026-12-13 每位教練每日須至少保留兩個未被預約的開放時段；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM @CoachMap cm CROSS JOIN @ScheduleDays days
      WHERE NOT EXISTS(SELECT 1 FROM dbo.classschedule cs WHERE cs.coachid=cm.coachid AND cs.classdate=days.D))
         THROW 51223,N''教練在 2026-10-30 至 2026-12-13 固定班表日期窗缺少班表；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM dbo.membercourse mc JOIN @PlanMap pm ON pm.membercourseid=mc.membercourseid
        WHERE (pm.PlanKey=N''A003_BASE'' AND mc.remainingsessions NOT BETWEEN 1 AND 5)
           OR (pm.PlanKey=N''A010_BASE'' AND mc.remainingsessions NOT BETWEEN 6 AND 10)
           OR (pm.PlanKey=N''A005_BASE'' AND (mc.remainingsessions<>0 OR mc.status<>N''usedup'')))
        THROW 51224,N''Amy 剩堂展示區間未達成；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM @PlanMap pm JOIN dbo.membercourse mc ON mc.membercourseid=pm.membercourseid
        WHERE pm.PlanKey=N''A007_BASE'' AND EXISTS(SELECT 1 FROM dbo.booking b JOIN dbo.attendance a ON a.bookingid=b.bookingid
          WHERE b.membercourseid=mc.membercourseid AND a.attendancestatus=N''PRESENT''))
        THROW 51225,N''A007_BASE 必須保持同課同教練從未 PRESENT；交易將回滾。'',1;
    IF NOT EXISTS (SELECT 1 FROM @PlanMap oldp JOIN dbo.renewal r ON r.membercourseid=oldp.membercourseid
        JOIN @PlanMap newp ON newp.membercourseid=r.newmembercourseid
        JOIN dbo.booking b ON b.membercourseid=newp.membercourseid JOIN dbo.attendance a ON a.bookingid=b.bookingid
        WHERE oldp.PlanKey=N''A013_BASE'' AND newp.PlanKey=N''A013_NEW'' AND a.attendancestatus=N''PRESENT''
          AND (SELECT MAX(cs2.classdate) FROM dbo.booking b2 JOIN dbo.attendance a2 ON a2.bookingid=b2.bookingid
               JOIN dbo.classschedule cs2 ON cs2.scheduleid=b2.scheduleid JOIN dbo.membercourse mc2 ON mc2.membercourseid=b2.membercourseid
               WHERE mc2.memberid=(SELECT memberid FROM @MemberMap WHERE memberno=N''M013'')
                 AND mc2.coachid=(SELECT coachid FROM @CoachMap WHERE coachno=N''C001'')
                 AND mc2.courseid=(SELECT courseid FROM @CourseMap WHERE CourseName=N''中階重訓'')
                 AND a2.attendancestatus=N''PRESENT'')>=CONVERT(date,''20261025'',112))
        THROW 51226,N''M013 新方案近期出席未更新同課同教練群組基準；交易將回滾。'',1;


    -- Validate the new display requirements without weakening database constraints.
    IF EXISTS (SELECT 1 FROM dbo.membercourse mc JOIN dbo.member m ON m.memberid=mc.memberid
      JOIN dbo.coach c ON c.coachid=mc.coachid
      WHERE c.coachno<>CASE WHEN m.memberno BETWEEN N''M001'' AND N''M015'' THEN N''C001''
            WHEN m.memberno BETWEEN N''M016'' AND N''M020'' THEN N''C002''
            WHEN m.memberno BETWEEN N''M021'' AND N''M025'' THEN N''C003''
            WHEN m.memberno BETWEEN N''M026'' AND N''M030'' THEN N''C004'' ELSE N''C005'' END)
      THROW 51227,N''固定會員與教練分配不符；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM dbo.booking b JOIN dbo.classschedule cs ON cs.scheduleid=b.scheduleid
       JOIN dbo.membercourse mc ON mc.membercourseid=b.membercourseid
       WHERE mc.coachid<>cs.coachid OR mc.courseid<>cs.courseid OR cs.classdate<mc.purchasedate)
      THROW 51228,N''Booking配對或購課日期不符；交易將回滾。'',1;
    IF EXISTS (SELECT scheduleid FROM dbo.booking WHERE bookingstatus=N''booked''
               GROUP BY scheduleid HAVING COUNT(*)>1)
      THROW 51229,N''同班表有重複有效預約；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM dbo.attendance a JOIN dbo.booking b ON b.bookingid=a.bookingid
       JOIN dbo.classschedule cs ON cs.scheduleid=b.scheduleid
       WHERE (a.attendancestatus<>N''PRESENT'' AND (a.workoutfocus IS NOT NULL OR a.checkintime IS NOT NULL))
          OR (a.attendancestatus=N''PRESENT'' AND a.checkintime IS NULL)
          OR a.checkintime>@SeedAsOf OR a.updatetime>@SeedAsOf)
      THROW 51230,N''出席內容或操作時間不符；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM dbo.inbodyrecords i
       WHERE i.recorddate>CONVERT(date,@SeedAsOf) OR i.weight IS NULL OR i.bodyfatpct IS NULL
          OR i.musclemass IS NULL OR i.weight<=0 OR i.bodyfatpct<=0 OR i.bodyfatpct>=100
          OR i.musclemass<=0 OR i.musclemass>=i.weight)
      THROW 51231,N''InBody日期或量測數值不符；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM @People p JOIN @MemberMap mm ON mm.memberno=p.memberno
       WHERE p.n<=15 AND
        (SELECT COUNT(DISTINCT i.recorddate) FROM dbo.inbodyrecords i WHERE i.memberid=mm.memberid)<3)
      THROW 51232,N''AMY學員量測未達三個不同上課日；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM dbo.attendance a JOIN dbo.booking b ON b.bookingid=a.bookingid
       JOIN dbo.classschedule cs ON cs.scheduleid=b.scheduleid
       JOIN dbo.membercourse mc ON mc.membercourseid=b.membercourseid
       JOIN @CoachMap cm ON cm.coachid=mc.coachid
       WHERE cm.coachno=N''C001'' AND a.attendancestatus=N''PRESENT'' AND b.bookingstatus=N''booked''
         AND NOT EXISTS(SELECT 1 FROM dbo.inbodyrecords i WHERE i.memberid=mc.memberid
           AND YEAR(i.recorddate)=YEAR(cs.classdate) AND MONTH(i.recorddate)=MONTH(cs.classdate)))
      THROW 51233,N''有實際出席的月份缺少InBody；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM dbo.renewal r
       JOIN dbo.membercourse src ON src.membercourseid=r.membercourseid
       JOIN dbo.membercourse dst ON dst.membercourseid=r.newmembercourseid
       WHERE src.memberid<>dst.memberid OR src.coachid<>dst.coachid
         OR dst.purchasedate<src.purchasedate OR dst.purchasedate>CONVERT(date,@SeedAsOf)
         OR r.addedsessions<>dst.totalsessions OR r.paymentmethod NOT IN(N''cash'',N''transfer'',N''card''))
      THROW 51234,N''Renewal新舊方案／付款方式不符；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM dbo.followup f JOIN dbo.membercourse mc ON mc.membercourseid=f.membercourseid
       WHERE f.coachid<>mc.coachid OR f.createdate>@SeedAsOf
          OR f.status NOT IN(N''NO_RESPONSE'',N''CONSIDERING'',N''AGREED'',N''DECLINED'')
          OR f.contactmethod NOT IN(N''PHONE'',N''MESSAGE'',N''IN_PERSON'',N''OTHER''))
      THROW 51235,N''FollowUp教練／日期／代碼不符；交易將回滾。'',1;
    IF EXISTS (SELECT 1 FROM dbo.followup f JOIN @PlanMap pm ON pm.membercourseid=f.membercourseid
       WHERE pm.PlanKey IN(N''A001_BASE'',N''A001_PURCHASE''))
      THROW 51236,N''新購課正常上課展示不應預建FollowUp；交易將回滾。'',1;
',N'@SeedAsOf datetime2(0)',@SeedAsOf=@RunAsOf;

    COMMIT TRANSACTION;
    SELECT N'RESET及匯入成功：已提交，腳本內資料檢查通過；API尚未驗證。' AS result,
      N'TEAM-RESET-20261102-R4' AS revision,DB_NAME() AS database_name,@RunAsOf AS SeedAsOfTaipei;

    -- Results: table counts, coach distinct members, key used-up case, and test accounts.
    SELECT N'useraccount' AS table_name,COUNT_BIG(*) AS row_count FROM dbo.useraccount
    UNION ALL SELECT N'coach',COUNT_BIG(*) FROM dbo.coach
    UNION ALL SELECT N'member',COUNT_BIG(*) FROM dbo.member
    UNION ALL SELECT N'course',COUNT_BIG(*) FROM dbo.course
    UNION ALL SELECT N'coachcourse',COUNT_BIG(*) FROM dbo.coachcourse
    UNION ALL SELECT N'membercourse',COUNT_BIG(*) FROM dbo.membercourse
    UNION ALL SELECT N'classschedule',COUNT_BIG(*) FROM dbo.classschedule
    UNION ALL SELECT N'booking',COUNT_BIG(*) FROM dbo.booking
    UNION ALL SELECT N'attendance',COUNT_BIG(*) FROM dbo.attendance
    UNION ALL SELECT N'inbodyrecords',COUNT_BIG(*) FROM dbo.inbodyrecords
    UNION ALL SELECT N'followup',COUNT_BIG(*) FROM dbo.followup
    UNION ALL SELECT N'renewal',COUNT_BIG(*) FROM dbo.renewal;

    SELECT c.coachno,c.name,COUNT(DISTINCT mc.memberid) AS distinct_students
    FROM dbo.coach c LEFT JOIN dbo.membercourse mc ON mc.coachid=c.coachid
    GROUP BY c.coachno,c.name ORDER BY c.coachno;
    SELECT m.memberno,m.name,COUNT(DISTINCT i.recorddate) AS inbody_dates,
      COUNT(DISTINCT CONVERT(char(7),i.recorddate,126)) AS inbody_months
    FROM dbo.member m JOIN dbo.membercourse mc ON mc.memberid=m.memberid
    JOIN dbo.coach c ON c.coachid=mc.coachid
    LEFT JOIN dbo.inbodyrecords i ON i.memberid=m.memberid
    WHERE c.coachno=N'C001' GROUP BY m.memberno,m.name ORDER BY m.memberno;
    SELECT m.memberno,mc.membercourseid,mc.totalsessions,mc.remainingsessions,mc.status,
      (SELECT COUNT(*) FROM dbo.booking b JOIN dbo.classschedule cs ON cs.scheduleid=b.scheduleid
       WHERE b.membercourseid=mc.membercourseid AND b.bookingstatus=N'booked'
         AND DATEADD(second,DATEDIFF(second,CONVERT(time(0),'00:00'),cs.starttime),
                     CONVERT(datetime2(0),cs.classdate))>@RunAsOf) AS future_bookings
    FROM dbo.membercourse mc JOIN dbo.member m ON m.memberid=mc.memberid WHERE m.memberno=N'M005';
    SELECT u.username,u.role,COALESCE(c.name,m.name,N'測試管理員') AS display_name
    FROM dbo.useraccount u LEFT JOIN dbo.coach c ON c.accountid=u.accountid
    LEFT JOIN dbo.member m ON m.accountid=u.accountid ORDER BY u.role,u.username;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    PRINT N'執行失敗；若仍在交易內，RESET及匯入已一起回滾。請保留完整錯誤。';
    THROW;
END CATCH;
GO
