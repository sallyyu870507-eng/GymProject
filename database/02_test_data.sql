/* 整理原因：整合 V2 的十二位會員與測試情境，教練、課程及授課配對採用 test5。
   執行順序：先完整執行 01_create_tables.sql，再完整執行本檔。
   本檔會依外鍵順序清除全部 12 張表、重設全部 11 個 IDENTITY，再新增完整測試資料，可重複執行。
   尚未實際執行驗證；僅完成檔案靜態檢查。 */
USE [gymproject];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
BEGIN TRANSACTION;
-- DEBUG原因：依子表到父表刪除；保留外鍵檢查，不以 NOCHECK 隱藏關聯問題。
DELETE FROM dbo.renewal;
DELETE FROM dbo.followup;
DELETE FROM dbo.inbodyrecords;
DELETE FROM dbo.attendance;
DELETE FROM dbo.booking;
DELETE FROM dbo.classschedule;
DELETE FROM dbo.membercourse;
DELETE FROM dbo.coachcourse;
DELETE FROM dbo.member;
DELETE FROM dbo.coach;
DELETE FROM dbo.course;
DELETE FROM dbo.useraccount;
-- DEBUG原因：DELETE 雖會清除資料，仍保留 IDENTITY 計數；原本只重設 course，其他表重跑後 ID 會持續增加。
-- 現在清空全部 12 張表後，逐一重設 11 張有 IDENTITY 的表；coachcourse 為複合主鍵，沒有 IDENTITY。
-- DEBUG原因：已使用過的表在 DELETE 後 RESEED 為 0，下一筆才會是 1。
-- 全新表或 TRUNCATE 後 last_value 為 NULL，保留原始 IDENTITY(1,1)，避免第一筆變成 0。
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'dbo.useraccount') AND last_value IS NOT NULL)
    DBCC CHECKIDENT (N'dbo.useraccount', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'dbo.coach') AND last_value IS NOT NULL)
    DBCC CHECKIDENT (N'dbo.coach', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'dbo.course') AND last_value IS NOT NULL)
    DBCC CHECKIDENT (N'dbo.course', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'dbo.member') AND last_value IS NOT NULL)
    DBCC CHECKIDENT (N'dbo.member', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'dbo.membercourse') AND last_value IS NOT NULL)
    DBCC CHECKIDENT (N'dbo.membercourse', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'dbo.classschedule') AND last_value IS NOT NULL)
    DBCC CHECKIDENT (N'dbo.classschedule', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'dbo.booking') AND last_value IS NOT NULL)
    DBCC CHECKIDENT (N'dbo.booking', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'dbo.attendance') AND last_value IS NOT NULL)
    DBCC CHECKIDENT (N'dbo.attendance', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'dbo.inbodyrecords') AND last_value IS NOT NULL)
    DBCC CHECKIDENT (N'dbo.inbodyrecords', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'dbo.followup') AND last_value IS NOT NULL)
    DBCC CHECKIDENT (N'dbo.followup', RESEED, 0) WITH NO_INFOMSGS;
IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'dbo.renewal') AND last_value IS NOT NULL)
    DBCC CHECKIDENT (N'dbo.renewal', RESEED, 0) WITH NO_INFOMSGS;
-- 整理原因：仍以 username 查找帳號、以 SCOPE_IDENTITY 捕捉新增 ID，確保重設編號後所有外鍵關聯正確。
-- 整理原因：test5 缺少 durationmin/status；五門課統一補為 60 分鐘及 active。
-- DEBUG原因：課程依序單筆新增，明確固定初階重訓、中階重訓、高階重訓、筋膜放鬆、TRX 的 ID 為 1～5。
INSERT INTO dbo.course(coursename,coursetype,description,durationmin,price,status) VALUES
(N'初階重訓',N'重量訓練',N'適合初學者的重量訓練課程，每堂 60 分鐘。',60,800,N'active');
INSERT INTO dbo.course(coursename,coursetype,description,durationmin,price,status) VALUES
(N'中階重訓',N'重量訓練',N'適合已有基礎、想進一步提升肌力的學員。',60,1000,N'active');
INSERT INTO dbo.course(coursename,coursetype,description,durationmin,price,status) VALUES
(N'高階重訓',N'重量訓練',N'適合有訓練經驗、想挑戰較高強度的學員。',60,1200,N'active');
INSERT INTO dbo.course(coursename,coursetype,description,durationmin,price,status) VALUES
(N'筋膜放鬆',N'伸展放鬆',N'透過筋膜放鬆練習，舒緩運動後的緊繃感。',60,700,N'active');
INSERT INTO dbo.course(coursename,coursetype,description,durationmin,price,status) VALUES
(N'TRX',N'懸吊訓練',N'利用懸吊器材進行全身肌力與核心訓練。',60,900,N'active');
-- 整理原因：五位教練 username 僅使用英文姓名（AMY、BEN、CHRIS、DAVID、ERIC），不含教練編號；同步修改 accountid 查找條件。
-- DEBUG原因：先建帳號，再一次填入教練所有必填欄位，修正 test5 先 INSERT 再 UPDATE 的錯誤。
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'AMY',N'123456',N'coach',N'active');
INSERT INTO dbo.coach(accountid,coachno,name,gender,phone,email,specialty,status) SELECT accountid,N'C001',N'AMY',N'女',N'0912345601',N'amy@example.com',N'初階重訓、中階重訓、TRX',N'active' FROM dbo.useraccount WHERE username=N'AMY';
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'BEN',N'123456',N'coach',N'active');
INSERT INTO dbo.coach(accountid,coachno,name,gender,phone,email,specialty,status) SELECT accountid,N'C002',N'BEN',N'男',N'0923456702',N'ben@example.com',N'筋膜放鬆',N'active' FROM dbo.useraccount WHERE username=N'BEN';
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'CHRIS',N'123456',N'coach',N'active');
INSERT INTO dbo.coach(accountid,coachno,name,gender,phone,email,specialty,status) SELECT accountid,N'C003',N'CHRIS',N'男',N'0934567803',N'chris@example.com',N'中階重訓、高階重訓',N'active' FROM dbo.useraccount WHERE username=N'CHRIS';
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'DAVID',N'123456',N'coach',N'active');
INSERT INTO dbo.coach(accountid,coachno,name,gender,phone,email,specialty,status) SELECT accountid,N'C004',N'DAVID',N'男',N'0945678904',N'david@example.com',N'初階重訓、筋膜放鬆',N'active' FROM dbo.useraccount WHERE username=N'DAVID';
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'ERIC',N'123456',N'coach',N'active');
INSERT INTO dbo.coach(accountid,coachno,name,gender,phone,email,specialty,status) SELECT accountid,N'C005',N'ERIC',N'男',N'0956789005',N'eric@example.com',N'高階重訓、TRX',N'active' FROM dbo.useraccount WHERE username=N'ERIC';
-- 整理原因：原封保留 test5 的十筆教練與課程配對，以業務編號 JOIN 真實 ID。
INSERT INTO dbo.coachcourse (coachid, courseid)
SELECT c.coachid, co.courseid
FROM (VALUES
    ('C001', N'初階重訓'),
    ('C001', N'中階重訓'),
    ('C001', N'TRX'),
    ('C002', N'筋膜放鬆'),
    ('C003', N'中階重訓'),
    ('C003', N'高階重訓'),
    ('C004', N'初階重訓'),
    ('C004', N'筋膜放鬆'),
    ('C005', N'高階重訓'),
    ('C005', N'TRX')
) AS mapping(coachno, coursename)
JOIN dbo.coach AS c ON c.coachno = mapping.coachno
JOIN dbo.course AS co ON co.coursename = mapping.coursename;
INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member001', N'123456', N'member', N'active');

DECLARE @account1 INT = SCOPE_IDENTITY();

INSERT INTO dbo.member
(accountid, memberno, name, gender, phone, email, birthday, status, avatarurl)
VALUES
(
    @account1,
    N'M001',
    N'王小美',
    N'女',
    N'0911111111',
    N'member001@gym.com',
    '1998-05-07',
    N'active',
  N'/avatars/member001.jpg'
);

DECLARE @member1 INT = SCOPE_IDENTITY();
INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member002', N'123456', N'member', N'active');

DECLARE @account2 INT = SCOPE_IDENTITY();

INSERT INTO dbo.member
(accountid, memberno, name, gender, phone, email, birthday, status, avatarurl)
VALUES
(
    @account2,
    N'M002',
    N'陳志豪',
    N'男',
    N'0922222222',
    N'member002@gym.com',
    '1995-08-15',
    N'active',
    N'/avatars/member002.jpg'
);

DECLARE @member2 INT = SCOPE_IDENTITY();
INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member003', N'123456', N'member', N'active');

DECLARE @account3 INT = SCOPE_IDENTITY();

INSERT INTO dbo.member
(accountid, memberno, name, gender, phone, email, birthday, status, avatarurl)
VALUES
(
    @account3,
    N'M003',
    N'林怡君',
    N'女',
    N'0933333333',
    N'member003@gym.com',
    '1992-03-18',
    N'active',
   N'/avatars/member003.jpg'
);

DECLARE @member3 INT = SCOPE_IDENTITY();
INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member004', N'123456', N'member', N'active');

DECLARE @account4 INT = SCOPE_IDENTITY();

INSERT INTO dbo.member
(accountid, memberno, name, gender, phone, email, birthday, status, avatarurl)
VALUES
(
    @account4,
    N'M004',
    N'張家豪',
    N'男',
    N'0944444444',
    N'member004@gym.com',
    '1989-11-25',
    N'active',
    N'/avatars/member004.jpg'
);

DECLARE @member4 INT = SCOPE_IDENTITY();
INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member005', N'123456', N'member', N'active');

DECLARE @account5 INT = SCOPE_IDENTITY();

INSERT INTO dbo.member
(accountid, memberno, name, gender, phone, email, birthday, status, avatarurl)
VALUES
(
    @account5,
    N'M005',
    N'李佳穎',
    N'女',
    N'0955555555',
    N'member005@gym.com',
    '1997-01-12',
    N'active',
    N'/avatars/member005.jpg'
);

DECLARE @member5 INT = SCOPE_IDENTITY();
INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member006', N'123456', N'member', N'active');

DECLARE @account6 INT = SCOPE_IDENTITY();

INSERT INTO dbo.member
(accountid, memberno, name, gender, phone, email, birthday, status, avatarurl)
VALUES
(
    @account6,
    N'M006',
    N'黃雅婷',
    N'女',
    N'0966666666',
    N'member006@gym.com',
    '1994-06-30',
    N'active',
    N'/avatars/member006.jpg'
);

DECLARE @member6 INT = SCOPE_IDENTITY();
INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member007', N'123456', N'member', N'active');

DECLARE @account7 INT = SCOPE_IDENTITY();

INSERT INTO dbo.member
(accountid, memberno, name, gender, phone, email, birthday, status, avatarurl)
VALUES
(
    @account7,
    N'M007',
    N'周子晴',
    N'女',
    N'0977000007',
    N'member007@gym.com',
    '1996-02-14',
    N'active',
    NULL
);

DECLARE @member7 INT = SCOPE_IDENTITY();
INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member008', N'123456', N'member', N'active');

DECLARE @account8 INT = SCOPE_IDENTITY();

INSERT INTO dbo.member
(accountid, memberno, name, gender, phone, email, birthday, status, avatarurl)
VALUES
(
    @account8,
    N'M008',
    N'吳承翰',
    N'男',
    N'0977000008',
    N'member008@gym.com',
    '1993-09-22',
    N'active',
    NULL
);

DECLARE @member8 INT = SCOPE_IDENTITY();
INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member009', N'123456', N'member', N'active');

DECLARE @account9 INT = SCOPE_IDENTITY();

INSERT INTO dbo.member
(accountid, memberno, name, gender, phone, email, birthday, status, avatarurl)
VALUES
(
    @account9,
    N'M009',
    N'許庭瑜',
    N'女',
    N'0977000009',
    N'member009@gym.com',
    '2000-04-09',
    N'active',
    NULL
);

DECLARE @member9 INT = SCOPE_IDENTITY();
INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member010', N'123456', N'member', N'active');

DECLARE @account10 INT = SCOPE_IDENTITY();

INSERT INTO dbo.member
(accountid, memberno, name, gender, phone, email, birthday, status, avatarurl)
VALUES
(
    @account10,
    N'M010',
    N'郭柏廷',
    N'男',
    N'0977000010',
    N'member010@gym.com',
    '1991-12-03',
    N'active',
    NULL
);

DECLARE @member10 INT = SCOPE_IDENTITY();
INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member011', N'123456', N'member', N'active');

DECLARE @account11 INT = SCOPE_IDENTITY();

INSERT INTO dbo.member
(accountid, memberno, name, gender, phone, email, birthday, status, avatarurl)
VALUES
(
    @account11,
    N'M011',
    N'蔡宜蓁',
    N'女',
    N'0977000011',
    N'member011@gym.com',
    '1998-07-19',
    N'active',
    NULL
);

DECLARE @member11 INT = SCOPE_IDENTITY();
INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member012', N'123456', N'member', N'active');

DECLARE @account12 INT = SCOPE_IDENTITY();

INSERT INTO dbo.member
(accountid, memberno, name, gender, phone, email, birthday, status, avatarurl)
VALUES
(
    @account12,
    N'M012',
    N'鄭宇翔',
    N'男',
    N'0977000012',
    N'member012@gym.com',
    '1994-10-28',
    N'active',
    NULL
);

DECLARE @member12 INT = SCOPE_IDENTITY();
-- 整理原因：十二筆購課分配到五位教練與五門課；保留 V2 的低堂數、用完及正常情境。
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) SELECT @member1,co.courseid,c.coachid,'20261001',20,2,N'active' FROM dbo.coach c CROSS JOIN dbo.course co WHERE c.coachno=N'C001' AND co.coursename=N'初階重訓';
DECLARE @mc1 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) SELECT @member2,co.courseid,c.coachid,'20261001',24,5,N'active' FROM dbo.coach c CROSS JOIN dbo.course co WHERE c.coachno=N'C001' AND co.coursename=N'中階重訓';
DECLARE @mc2 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) SELECT @member3,co.courseid,c.coachid,'20261001',20,12,N'active' FROM dbo.coach c CROSS JOIN dbo.course co WHERE c.coachno=N'C003' AND co.coursename=N'高階重訓';
DECLARE @mc3 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) SELECT @member4,co.courseid,c.coachid,'20261001',20,0,N'active' FROM dbo.coach c CROSS JOIN dbo.course co WHERE c.coachno=N'C002' AND co.coursename=N'筋膜放鬆';
DECLARE @mc4 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) SELECT @member5,co.courseid,c.coachid,'20261001',30,15,N'active' FROM dbo.coach c CROSS JOIN dbo.course co WHERE c.coachno=N'C005' AND co.coursename=N'TRX';
DECLARE @mc5 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) SELECT @member6,co.courseid,c.coachid,'20261001',16,2,N'active' FROM dbo.coach c CROSS JOIN dbo.course co WHERE c.coachno=N'C004' AND co.coursename=N'初階重訓';
DECLARE @mc6 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) SELECT @member7,co.courseid,c.coachid,'20261001',20,10,N'active' FROM dbo.coach c CROSS JOIN dbo.course co WHERE c.coachno=N'C004' AND co.coursename=N'筋膜放鬆';
DECLARE @mc7 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) SELECT @member8,co.courseid,c.coachid,'20261001',24,4,N'active' FROM dbo.coach c CROSS JOIN dbo.course co WHERE c.coachno=N'C003' AND co.coursename=N'中階重訓';
DECLARE @mc8 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) SELECT @member9,co.courseid,c.coachid,'20261001',16,9,N'active' FROM dbo.coach c CROSS JOIN dbo.course co WHERE c.coachno=N'C005' AND co.coursename=N'高階重訓';
DECLARE @mc9 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) SELECT @member10,co.courseid,c.coachid,'20261001',20,1,N'active' FROM dbo.coach c CROSS JOIN dbo.course co WHERE c.coachno=N'C001' AND co.coursename=N'TRX';
DECLARE @mc10 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) SELECT @member11,co.courseid,c.coachid,'20261001',30,18,N'active' FROM dbo.coach c CROSS JOIN dbo.course co WHERE c.coachno=N'C002' AND co.coursename=N'筋膜放鬆';
DECLARE @mc11 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) SELECT @member12,co.courseid,c.coachid,'20261001',24,5,N'active' FROM dbo.coach c CROSS JOIN dbo.course co WHERE c.coachno=N'C005' AND co.coursename=N'TRX';
DECLARE @mc12 int = CONVERT(int,SCOPE_IDENTITY());
-- DEBUG原因：以購課資料決定排課教練與課程，避免預約與購課屬於不同教練／課程。
-- 整理原因：共 17 堂，日期涵蓋 2026-11-01～2026-11-13 每一天，起訖日均有資料。
-- 測試情境為 2026-11-13 的資料快照；出席日期不隨實際執行日改變。
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) SELECT coachid,courseid,'20261101','09:00:00','10:00:00',N'A教室',N'closed' FROM dbo.membercourse WHERE membercourseid=@mc1;
DECLARE @s1 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES(@mc1,@s1,'20261025',N'BOOKED',N'整合測試預約','20261025');
DECLARE @b1 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@b1,'20261101 09:00:00',N'PRESENT',N'課程訓練',N'整合測試出席','20261101 09:00:00');
DECLARE @a1 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) SELECT coachid,courseid,'20261102','09:00:00','10:00:00',N'A教室',N'closed' FROM dbo.membercourse WHERE membercourseid=@mc2;
DECLARE @s2 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES(@mc2,@s2,'20261025',N'BOOKED',N'整合測試預約','20261025');
DECLARE @b2 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@b2,'20261102 09:00:00',N'PRESENT',N'課程訓練',N'整合測試出席','20261102 09:00:00');
DECLARE @a2 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) SELECT coachid,courseid,'20261103','09:00:00','10:00:00',N'A教室',N'closed' FROM dbo.membercourse WHERE membercourseid=@mc3;
DECLARE @s3 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES(@mc3,@s3,'20261025',N'BOOKED',N'整合測試預約','20261025');
DECLARE @b3 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@b3,'20261103 09:00:00',N'PRESENT',N'課程訓練',N'整合測試出席','20261103 09:00:00');
DECLARE @a3 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) SELECT coachid,courseid,'20261104','09:00:00','10:00:00',N'A教室',N'closed' FROM dbo.membercourse WHERE membercourseid=@mc4;
DECLARE @s4 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES(@mc4,@s4,'20261025',N'BOOKED',N'整合測試預約','20261025');
DECLARE @b4 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@b4,NULL,N'ABSENT',N'課程訓練',N'整合測試出席','20261104 09:00:00');
DECLARE @a4 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) SELECT coachid,courseid,'20261105','09:00:00','10:00:00',N'A教室',N'closed' FROM dbo.membercourse WHERE membercourseid=@mc5;
DECLARE @s5 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES(@mc5,@s5,'20261025',N'BOOKED',N'整合測試預約','20261025');
DECLARE @b5 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@b5,'20261105 09:00:00',N'PRESENT',N'課程訓練',N'整合測試出席','20261105 09:00:00');
DECLARE @a5 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) SELECT coachid,courseid,'20261106','09:00:00','10:00:00',N'A教室',N'closed' FROM dbo.membercourse WHERE membercourseid=@mc6;
DECLARE @s6 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES(@mc6,@s6,'20261025',N'BOOKED',N'整合測試預約','20261025');
DECLARE @b6 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@b6,'20261106 09:00:00',N'PRESENT',N'課程訓練',N'整合測試出席','20261106 09:00:00');
DECLARE @a6 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) SELECT coachid,courseid,'20261107','09:00:00','10:00:00',N'A教室',N'closed' FROM dbo.membercourse WHERE membercourseid=@mc7;
DECLARE @s7 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES(@mc7,@s7,'20261025',N'BOOKED',N'整合測試預約','20261025');
DECLARE @b7 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@b7,'20261107 09:00:00',N'PRESENT',N'課程訓練',N'整合測試出席','20261107 09:00:00');
DECLARE @a7 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) SELECT coachid,courseid,'20261108','09:00:00','10:00:00',N'A教室',N'closed' FROM dbo.membercourse WHERE membercourseid=@mc8;
DECLARE @s8 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES(@mc8,@s8,'20261025',N'BOOKED',N'整合測試預約','20261025');
DECLARE @b8 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@b8,'20261108 09:00:00',N'PRESENT',N'課程訓練',N'整合測試出席','20261108 09:00:00');
DECLARE @a8 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) SELECT coachid,courseid,'20261109','09:00:00','10:00:00',N'A教室',N'closed' FROM dbo.membercourse WHERE membercourseid=@mc9;
DECLARE @s9 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES(@mc9,@s9,'20261025',N'BOOKED',N'整合測試預約','20261025');
DECLARE @b9 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@b9,'20261109 09:00:00',N'PRESENT',N'課程訓練',N'整合測試出席','20261109 09:00:00');
DECLARE @a9 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) SELECT coachid,courseid,'20261110','09:00:00','10:00:00',N'A教室',N'closed' FROM dbo.membercourse WHERE membercourseid=@mc10;
DECLARE @s10 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES(@mc10,@s10,'20261025',N'BOOKED',N'整合測試預約','20261025');
DECLARE @b10 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@b10,'20261110 09:00:00',N'PRESENT',N'課程訓練',N'整合測試出席','20261110 09:00:00');
DECLARE @a10 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) SELECT coachid,courseid,'20261111','09:00:00','10:00:00',N'A教室',N'open' FROM dbo.membercourse WHERE membercourseid=@mc11;
DECLARE @s11 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES(@mc11,@s11,'20261025',N'BOOKED',N'整合測試預約','20261025');
DECLARE @b11 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@b11,NULL,N'PENDING',N'課程訓練',N'整合測試出席',NULL);
DECLARE @a11 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) SELECT coachid,courseid,'20261112','09:00:00','10:00:00',N'A教室',N'open' FROM dbo.membercourse WHERE membercourseid=@mc12;
DECLARE @s12 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES(@mc12,@s12,'20261025',N'BOOKED',N'整合測試預約','20261025');
DECLARE @b12 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@b12,NULL,N'PENDING',N'課程訓練',N'整合測試出席',NULL);
DECLARE @a12 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) SELECT coachid,courseid,'20261113','09:00:00','10:00:00',N'A教室',N'closed' FROM dbo.membercourse WHERE membercourseid=@mc1;
DECLARE @s13 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES(@mc1,@s13,'20261025',N'BOOKED',N'整合測試預約','20261025');
DECLARE @b13 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@b13,'20261113 09:00:00',N'PRESENT',N'課程訓練',N'整合測試出席','20261113 09:00:00');
DECLARE @a13 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) SELECT coachid,courseid,'20261113','10:00:00','11:00:00',N'A教室',N'closed' FROM dbo.membercourse WHERE membercourseid=@mc2;
DECLARE @s14 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES(@mc2,@s14,'20261025',N'BOOKED',N'整合測試預約','20261025');
DECLARE @b14 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@b14,NULL,N'LEAVE',N'課程訓練',N'整合測試出席','20261113 10:00:00');
DECLARE @a14 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) SELECT coachid,courseid,'20261113','12:00:00','13:00:00',N'A教室',N'open' FROM dbo.membercourse WHERE membercourseid=@mc3;
DECLARE @s15 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES(@mc3,@s15,'20261025',N'CANCELLED',N'整合測試預約','20261025');
DECLARE @b15 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) SELECT coachid,courseid,'20261113','14:00:00','15:00:00',N'A教室',N'open' FROM dbo.membercourse WHERE membercourseid=@mc5;
DECLARE @s16 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES(@mc5,@s16,'20261025',N'BOOKED',N'整合測試預約','20261025');
DECLARE @b16 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@b16,NULL,N'PENDING',N'課程訓練',N'整合測試出席',NULL);
DECLARE @a16 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) SELECT coachid,courseid,'20261113','16:00:00','17:00:00',N'A教室',N'open' FROM dbo.membercourse WHERE membercourseid=@mc6;
DECLARE @s17 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES(@mc6,@s17,'20261025',N'BOOKED',N'整合測試預約','20261025');
DECLARE @b17 int = CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@b17,NULL,N'PENDING',N'課程訓練',N'整合測試出席',NULL);
DECLARE @a17 int = CONVERT(int,SCOPE_IDENTITY());
-- DEBUG原因：InBody 只連結 PRESENT，會員由同筆出席反查，量測日與上課日相同。
INSERT INTO dbo.inbodyrecords(memberid,recorddate,weight,bodyfatpct,musclemass,attendanceid) SELECT mc.memberid,cs.classdate,65.0,25.0,25.0,a.attendanceid FROM dbo.attendance a JOIN dbo.booking bk ON bk.bookingid=a.bookingid JOIN dbo.membercourse mc ON mc.membercourseid=bk.membercourseid JOIN dbo.classschedule cs ON cs.scheduleid=bk.scheduleid WHERE a.attendanceid=@a1 AND a.attendancestatus=N'PRESENT';
INSERT INTO dbo.inbodyrecords(memberid,recorddate,weight,bodyfatpct,musclemass,attendanceid) SELECT mc.memberid,cs.classdate,65.0,25.0,25.0,a.attendanceid FROM dbo.attendance a JOIN dbo.booking bk ON bk.bookingid=a.bookingid JOIN dbo.membercourse mc ON mc.membercourseid=bk.membercourseid JOIN dbo.classschedule cs ON cs.scheduleid=bk.scheduleid WHERE a.attendanceid=@a2 AND a.attendancestatus=N'PRESENT';
INSERT INTO dbo.inbodyrecords(memberid,recorddate,weight,bodyfatpct,musclemass,attendanceid) SELECT mc.memberid,cs.classdate,65.0,25.0,25.0,a.attendanceid FROM dbo.attendance a JOIN dbo.booking bk ON bk.bookingid=a.bookingid JOIN dbo.membercourse mc ON mc.membercourseid=bk.membercourseid JOIN dbo.classschedule cs ON cs.scheduleid=bk.scheduleid WHERE a.attendanceid=@a3 AND a.attendancestatus=N'PRESENT';
INSERT INTO dbo.inbodyrecords(memberid,recorddate,weight,bodyfatpct,musclemass,attendanceid) SELECT mc.memberid,cs.classdate,65.0,25.0,25.0,a.attendanceid FROM dbo.attendance a JOIN dbo.booking bk ON bk.bookingid=a.bookingid JOIN dbo.membercourse mc ON mc.membercourseid=bk.membercourseid JOIN dbo.classschedule cs ON cs.scheduleid=bk.scheduleid WHERE a.attendanceid=@a5 AND a.attendancestatus=N'PRESENT';
INSERT INTO dbo.inbodyrecords(memberid,recorddate,weight,bodyfatpct,musclemass,attendanceid) SELECT mc.memberid,cs.classdate,65.0,25.0,25.0,a.attendanceid FROM dbo.attendance a JOIN dbo.booking bk ON bk.bookingid=a.bookingid JOIN dbo.membercourse mc ON mc.membercourseid=bk.membercourseid JOIN dbo.classschedule cs ON cs.scheduleid=bk.scheduleid WHERE a.attendanceid=@a6 AND a.attendancestatus=N'PRESENT';
INSERT INTO dbo.inbodyrecords(memberid,recorddate,weight,bodyfatpct,musclemass,attendanceid) SELECT mc.memberid,cs.classdate,65.0,25.0,25.0,a.attendanceid FROM dbo.attendance a JOIN dbo.booking bk ON bk.bookingid=a.bookingid JOIN dbo.membercourse mc ON mc.membercourseid=bk.membercourseid JOIN dbo.classschedule cs ON cs.scheduleid=bk.scheduleid WHERE a.attendanceid=@a13 AND a.attendancestatus=N'PRESENT';
-- 整理原因：續約追蹤沿用 V2 五種聯絡情境；負責教練取自各筆購課，不再全部寫死同一人。
INSERT INTO dbo.followup(membercourseid,coachid,status,note,createdate,contactmethod) SELECT membercourseid,coachid,N'CONSIDERING',N'近期工作忙碌，預計下週重新安排課程。','20261113 18:00',N'LINE' FROM dbo.membercourse WHERE membercourseid=@mc3;
INSERT INTO dbo.followup(membercourseid,coachid,status,note,createdate,contactmethod) SELECT membercourseid,coachid,N'DECLINED',N'目前因預算考量暫不續約。','20261113 18:00',N'IN_PERSON' FROM dbo.membercourse WHERE membercourseid=@mc4;
INSERT INTO dbo.followup(membercourseid,coachid,status,note,createdate,contactmethod) SELECT membercourseid,coachid,N'AGREED',N'學員已表示願意續約，待確認付款方式。','20261113 18:00',N'PHONE' FROM dbo.membercourse WHERE membercourseid=@mc2;
INSERT INTO dbo.followup(membercourseid,coachid,status,note,createdate,contactmethod) SELECT membercourseid,coachid,N'CONSIDERING',N'已告知剩餘堂數不多，學員表示會考慮續約。','20261113 18:00',N'LINE' FROM dbo.membercourse WHERE membercourseid=@mc1;
INSERT INTO dbo.followup(membercourseid,coachid,status,note,createdate,contactmethod) SELECT membercourseid,coachid,N'NOT_CONTACTED',N'尚未聯繫，建議優先關懷。','20261113 18:00',N'OTHER' FROM dbo.membercourse WHERE membercourseid=@mc6;
-- DEBUG原因：續約金額改用實際購買課程單價（TRX 900 × 10 = 9000），並同步總堂數與剩餘堂數。
INSERT INTO dbo.renewal(membercourseid,renewaldate,addedsessions,amount,paymentmethod,note)
SELECT mc.membercourseid,'20261113 18:30',10,co.price*10,N'CREDIT_CARD',N'加購10堂；總堂數及剩餘堂數均已增加10堂'
FROM dbo.membercourse mc JOIN dbo.course co ON co.courseid=mc.courseid WHERE mc.membercourseid=@mc5;
UPDATE dbo.membercourse SET totalsessions=totalsessions+10,remainingsessions=remainingsessions+10 WHERE membercourseid=@mc5;
-- 整理原因：其餘購課堂數為含歷史使用量的快照，並非只扣除本檔列出的出席。

-- DEBUG原因：以下為執行時的關聯驗收，有問題即回復整份測試資料；尚未實際執行驗證。
IF (SELECT MIN(courseid) FROM dbo.course) <> 1 OR (SELECT MAX(courseid) FROM dbo.course) <> 5
 THROW 51005,N'課程編號應為 1 至 5',1;
IF EXISTS (
 SELECT 1 FROM dbo.booking b JOIN dbo.membercourse mc ON mc.membercourseid=b.membercourseid
 JOIN dbo.classschedule cs ON cs.scheduleid=b.scheduleid
 WHERE mc.coachid<>cs.coachid OR mc.courseid<>cs.courseid
) THROW 51001,N'預約與購課的教練或課程不一致',1;
IF EXISTS (
 SELECT 1 FROM dbo.inbodyrecords i JOIN dbo.attendance a ON a.attendanceid=i.attendanceid
 JOIN dbo.booking b ON b.bookingid=a.bookingid JOIN dbo.membercourse mc ON mc.membercourseid=b.membercourseid
 JOIN dbo.classschedule cs ON cs.scheduleid=b.scheduleid
 WHERE i.memberid<>mc.memberid OR a.attendancestatus<>N'PRESENT' OR i.recorddate<>cs.classdate
) THROW 51002,N'InBody 會員、出席狀態或量測日不一致',1;
IF (SELECT MIN(classdate) FROM dbo.classschedule)<>'20261101'
 OR (SELECT MAX(classdate) FROM dbo.classschedule)<>'20261113'
 OR (SELECT COUNT(DISTINCT classdate) FROM dbo.classschedule)<>13
 THROW 51003,N'排課日期未完整涵蓋指定期間',1;
-- DEBUG原因：逐表核對預期筆數，避免 INSERT ... SELECT 因查無對應而靜默少建資料。
DECLARE @expected TABLE(tablename sysname, expectedcount int);
INSERT INTO @expected VALUES
(N'useraccount',17),(N'coach',5),(N'course',5),(N'coachcourse',10),
(N'member',12),(N'membercourse',12),(N'classschedule',17),(N'booking',17),
(N'attendance',16),(N'inbodyrecords',6),(N'followup',5),(N'renewal',1);
DECLARE @actual TABLE(tablename sysname, actualcount int);
INSERT INTO @actual
SELECT N'useraccount',COUNT(*) FROM dbo.useraccount UNION ALL
SELECT N'coach',COUNT(*) FROM dbo.coach UNION ALL
SELECT N'course',COUNT(*) FROM dbo.course UNION ALL
SELECT N'coachcourse',COUNT(*) FROM dbo.coachcourse UNION ALL
SELECT N'member',COUNT(*) FROM dbo.member UNION ALL
SELECT N'membercourse',COUNT(*) FROM dbo.membercourse UNION ALL
SELECT N'classschedule',COUNT(*) FROM dbo.classschedule UNION ALL
SELECT N'booking',COUNT(*) FROM dbo.booking UNION ALL
SELECT N'attendance',COUNT(*) FROM dbo.attendance UNION ALL
SELECT N'inbodyrecords',COUNT(*) FROM dbo.inbodyrecords UNION ALL
SELECT N'followup',COUNT(*) FROM dbo.followup UNION ALL
SELECT N'renewal',COUNT(*) FROM dbo.renewal;
IF EXISTS(SELECT 1 FROM @expected e LEFT JOIN @actual a ON a.tablename=e.tablename WHERE a.actualcount IS NULL OR a.actualcount<>e.expectedcount)
 THROW 51004,N'測試資料筆數不符預期',1;
-- DEBUG原因：除核對筆數外，也驗收所有 IDENTITY 的起訖值；配合主鍵唯一性與筆數檢查，確保編號完整為 1～預期筆數。
IF (SELECT MIN(accountid) FROM dbo.useraccount) <> 1 OR (SELECT MAX(accountid) FROM dbo.useraccount) <> 17
 THROW 51006,N'useraccount 的 IDENTITY 編號不符預期',1;
IF (SELECT MIN(coachid) FROM dbo.coach) <> 1 OR (SELECT MAX(coachid) FROM dbo.coach) <> 5
 THROW 51006,N'coach 的 IDENTITY 編號不符預期',1;
IF (SELECT MIN(courseid) FROM dbo.course) <> 1 OR (SELECT MAX(courseid) FROM dbo.course) <> 5
 THROW 51006,N'course 的 IDENTITY 編號不符預期',1;
IF (SELECT MIN(memberid) FROM dbo.member) <> 1 OR (SELECT MAX(memberid) FROM dbo.member) <> 12
 THROW 51006,N'member 的 IDENTITY 編號不符預期',1;
IF (SELECT MIN(membercourseid) FROM dbo.membercourse) <> 1 OR (SELECT MAX(membercourseid) FROM dbo.membercourse) <> 12
 THROW 51006,N'membercourse 的 IDENTITY 編號不符預期',1;
IF (SELECT MIN(scheduleid) FROM dbo.classschedule) <> 1 OR (SELECT MAX(scheduleid) FROM dbo.classschedule) <> 17
 THROW 51006,N'classschedule 的 IDENTITY 編號不符預期',1;
IF (SELECT MIN(bookingid) FROM dbo.booking) <> 1 OR (SELECT MAX(bookingid) FROM dbo.booking) <> 17
 THROW 51006,N'booking 的 IDENTITY 編號不符預期',1;
IF (SELECT MIN(attendanceid) FROM dbo.attendance) <> 1 OR (SELECT MAX(attendanceid) FROM dbo.attendance) <> 16
 THROW 51006,N'attendance 的 IDENTITY 編號不符預期',1;
IF (SELECT MIN(inbodyid) FROM dbo.inbodyrecords) <> 1 OR (SELECT MAX(inbodyid) FROM dbo.inbodyrecords) <> 6
 THROW 51006,N'inbodyrecords 的 IDENTITY 編號不符預期',1;
IF (SELECT MIN(followupid) FROM dbo.followup) <> 1 OR (SELECT MAX(followupid) FROM dbo.followup) <> 5
 THROW 51006,N'followup 的 IDENTITY 編號不符預期',1;
IF (SELECT MIN(renewalid) FROM dbo.renewal) <> 1 OR (SELECT MAX(renewalid) FROM dbo.renewal) <> 1
 THROW 51006,N'renewal 的 IDENTITY 編號不符預期',1;
COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
-- 整理原因：輸出所有表的資料筆數，方便在 SSMS 核對。
SELECT N'useraccount' AS tablename,COUNT(*) AS [rowcount] FROM dbo.useraccount
UNION ALL
SELECT N'coach' AS tablename,COUNT(*) AS [rowcount] FROM dbo.coach
UNION ALL
SELECT N'course' AS tablename,COUNT(*) AS [rowcount] FROM dbo.course
UNION ALL
SELECT N'coachcourse' AS tablename,COUNT(*) AS [rowcount] FROM dbo.coachcourse
UNION ALL
SELECT N'member' AS tablename,COUNT(*) AS [rowcount] FROM dbo.member
UNION ALL
SELECT N'membercourse' AS tablename,COUNT(*) AS [rowcount] FROM dbo.membercourse
UNION ALL
SELECT N'classschedule' AS tablename,COUNT(*) AS [rowcount] FROM dbo.classschedule
UNION ALL
SELECT N'booking' AS tablename,COUNT(*) AS [rowcount] FROM dbo.booking
UNION ALL
SELECT N'attendance' AS tablename,COUNT(*) AS [rowcount] FROM dbo.attendance
UNION ALL
SELECT N'inbodyrecords' AS tablename,COUNT(*) AS [rowcount] FROM dbo.inbodyrecords
UNION ALL
SELECT N'followup' AS tablename,COUNT(*) AS [rowcount] FROM dbo.followup
UNION ALL
SELECT N'renewal' AS tablename,COUNT(*) AS [rowcount] FROM dbo.renewal;

-- 整理原因：逐表輸出完整測試資料，方便在 SSMS 結果區查看。

-- 表名：useraccount
SELECT * FROM dbo.useraccount;

-- 表名：coach
SELECT * FROM dbo.coach;

-- 表名：course
SELECT * FROM dbo.course;

-- 表名：coachcourse
SELECT * FROM dbo.coachcourse;

-- 表名：member
SELECT * FROM dbo.member;

-- 表名：membercourse
SELECT * FROM dbo.membercourse;

-- 表名：classschedule
SELECT * FROM dbo.classschedule;

-- 表名：booking
SELECT * FROM dbo.booking;

-- 表名：attendance
SELECT * FROM dbo.attendance;

-- 表名：inbodyrecords
SELECT * FROM dbo.inbodyrecords;

-- 表名：followup
SELECT * FROM dbo.followup;

-- 表名：renewal
SELECT * FROM dbo.renewal;
