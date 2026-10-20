/* 警告：清空 gymproject 全部十二張功能表的資料並重設 IDENTITY；不修改結構。
先備份，再確認新版建表成功；SSMS 開啟本檔，不反白，整份 F5。
SQL Server 2016+；Asia/Taipei 對應 Windows Taipei Standard Time。
基準時間取執行當下台北時間；15:00 前完整展示日為昨天，15:00 起為今天。
完成狀態排在展示日 08:00～14:00 內；今天另保留待確認。
尚未在 SQL Server 實際執行；預期資料已由 Python 生成器檢查。 */
USE [gymproject];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Now datetime=CAST(SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'Taipei Standard Time' AS datetime);
DECLARE @Today date=CAST(@Now AS date);
DECLARE @ShowDate date=CASE WHEN CAST(@Now AS time)>='15:00' THEN @Today ELSE DATEADD(day,-1,@Today) END;
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
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'AMY',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'coach',N'active');
INSERT INTO dbo.coach(accountid,coachno,name,gender,phone,email,specialty,status) SELECT accountid,N'C001',N'AMY',N'女',N'0912345601',N'amy@example.com',N'初階重訓、中階重訓、TRX',N'active' FROM dbo.useraccount WHERE username=N'AMY';
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'BEN',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'coach',N'active');
INSERT INTO dbo.coach(accountid,coachno,name,gender,phone,email,specialty,status) SELECT accountid,N'C002',N'BEN',N'男',N'0923456702',N'ben@example.com',N'筋膜放鬆',N'active' FROM dbo.useraccount WHERE username=N'BEN';
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'CHRIS',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'coach',N'active');
INSERT INTO dbo.coach(accountid,coachno,name,gender,phone,email,specialty,status) SELECT accountid,N'C003',N'CHRIS',N'男',N'0934567803',N'chris@example.com',N'中階重訓、高階重訓',N'active' FROM dbo.useraccount WHERE username=N'CHRIS';
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'DAVID',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'coach',N'active');
INSERT INTO dbo.coach(accountid,coachno,name,gender,phone,email,specialty,status) SELECT accountid,N'C004',N'DAVID',N'男',N'0945678904',N'david@example.com',N'初階重訓、筋膜放鬆',N'active' FROM dbo.useraccount WHERE username=N'DAVID';
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'ERIC',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'coach',N'active');
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
(N'member001', N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi', N'member', N'active');

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
(N'member002', N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi', N'member', N'active');

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
(N'member003', N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi', N'member', N'active');

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
(N'member004', N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi', N'member', N'active');

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
(N'member005', N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi', N'member', N'active');

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
(N'member006', N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi', N'member', N'active');

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
(N'member007', N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi', N'member', N'active');

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
(N'member008', N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi', N'member', N'active');

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
(N'member009', N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi', N'member', N'active');

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
(N'member010', N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi', N'member', N'active');

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
(N'member011', N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi', N'member', N'active');

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
(N'member012', N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi', N'member', N'active');

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

INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member013',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account13 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account13,N'M013',N'測試學員013',N'女',N'0988000013',N'member013@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member13 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member014',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account14 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account14,N'M014',N'測試學員014',N'男',N'0988000014',N'member014@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member14 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member015',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account15 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account15,N'M015',N'測試學員015',N'女',N'0988000015',N'member015@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member15 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member016',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account16 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account16,N'M016',N'測試學員016',N'男',N'0988000016',N'member016@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member16 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member017',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account17 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account17,N'M017',N'測試學員017',N'女',N'0988000017',N'member017@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member17 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member018',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account18 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account18,N'M018',N'測試學員018',N'男',N'0988000018',N'member018@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member18 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member019',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account19 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account19,N'M019',N'測試學員019',N'女',N'0988000019',N'member019@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member19 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member020',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account20 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account20,N'M020',N'測試學員020',N'男',N'0988000020',N'member020@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member20 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member021',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account21 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account21,N'M021',N'測試學員021',N'女',N'0988000021',N'member021@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member21 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member022',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account22 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account22,N'M022',N'測試學員022',N'男',N'0988000022',N'member022@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member22 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member023',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account23 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account23,N'M023',N'測試學員023',N'女',N'0988000023',N'member023@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member23 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member024',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account24 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account24,N'M024',N'測試學員024',N'男',N'0988000024',N'member024@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member24 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member025',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account25 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account25,N'M025',N'測試學員025',N'女',N'0988000025',N'member025@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member25 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member026',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account26 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account26,N'M026',N'測試學員026',N'男',N'0988000026',N'member026@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member26 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member027',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account27 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account27,N'M027',N'測試學員027',N'女',N'0988000027',N'member027@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member27 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member028',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account28 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account28,N'M028',N'測試學員028',N'男',N'0988000028',N'member028@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member28 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member029',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account29 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account29,N'M029',N'測試學員029',N'女',N'0988000029',N'member029@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member29 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member030',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account30 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account30,N'M030',N'測試學員030',N'男',N'0988000030',N'member030@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member30 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member031',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account31 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account31,N'M031',N'測試學員031',N'女',N'0988000031',N'member031@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member31 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member032',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account32 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account32,N'M032',N'測試學員032',N'男',N'0988000032',N'member032@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member32 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member033',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account33 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account33,N'M033',N'測試學員033',N'女',N'0988000033',N'member033@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member33 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member034',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account34 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account34,N'M034',N'測試學員034',N'男',N'0988000034',N'member034@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member34 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member035',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account35 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account35,N'M035',N'測試學員035',N'女',N'0988000035',N'member035@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member35 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member036',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account36 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account36,N'M036',N'測試學員036',N'男',N'0988000036',N'member036@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member36 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member037',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account37 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account37,N'M037',N'測試學員037',N'女',N'0988000037',N'member037@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member37 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member038',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account38 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account38,N'M038',N'測試學員038',N'男',N'0988000038',N'member038@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member38 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member039',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account39 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account39,N'M039',N'測試學員039',N'女',N'0988000039',N'member039@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member39 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member040',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account40 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account40,N'M040',N'測試學員040',N'男',N'0988000040',N'member040@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member40 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member041',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account41 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account41,N'M041',N'測試學員041',N'女',N'0988000041',N'member041@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member41 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member042',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account42 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account42,N'M042',N'測試學員042',N'男',N'0988000042',N'member042@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member42 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member043',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account43 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account43,N'M043',N'測試學員043',N'女',N'0988000043',N'member043@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member43 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member044',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account44 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account44,N'M044',N'測試學員044',N'男',N'0988000044',N'member044@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member44 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member045',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account45 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account45,N'M045',N'測試學員045',N'女',N'0988000045',N'member045@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member45 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member046',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account46 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account46,N'M046',N'測試學員046',N'男',N'0988000046',N'member046@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member46 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member047',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account47 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account47,N'M047',N'測試學員047',N'女',N'0988000047',N'member047@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member47 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member048',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account48 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account48,N'M048',N'測試學員048',N'男',N'0988000048',N'member048@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member48 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member049',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account49 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account49,N'M049',N'測試學員049',N'女',N'0988000049',N'member049@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member49 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'member050',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'member',N'active');
DECLARE @account50 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.member(accountid,memberno,name,gender,phone,email,birthday,status,avatarurl) VALUES(@account50,N'M050',N'測試學員050',N'男',N'0988000050',N'member050@gym.com',N'1996-06-15',N'active',NULL);
DECLARE @member50 int=CONVERT(int,SCOPE_IDENTITY());
INSERT INTO dbo.useraccount(username,password,role,status) VALUES(N'admin',N'$2a$12$fJyBnjw66ljgKhXn/0/R7.Rw9xENvbFu9SDODc2sA29jVIoPJFloi',N'admin',N'active');
DECLARE @AdminAccountId int=CONVERT(int,SCOPE_IDENTITY());
DECLARE @PlanMap TABLE(casekey int PRIMARY KEY, membercourseid int UNIQUE);
DECLARE @ScheduleMap TABLE(casekey int PRIMARY KEY,scheduleid int UNIQUE);
DECLARE @BookingMap TABLE(casekey int PRIMARY KEY,bookingid int UNIQUE);
DECLARE @AttendanceMap TABLE(casekey int PRIMARY KEY,attendanceid int UNIQUE);
DECLARE @NewId int;
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member1,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),DATEADD(day,-95,@Today),8,1,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(1,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member2,(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),DATEADD(day,-95,@Today),11,5,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(2,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member3,(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-95,@Today),8,1,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(3,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member4,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),DATEADD(day,-95,@Today),8,1,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(4,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member5,(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),DATEADD(day,-95,@Today),8,1,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(5,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member6,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),DATEADD(day,-95,@Today),8,1,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(6,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member7,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),DATEADD(day,-95,@Today),11,5,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(7,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member8,(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-95,@Today),11,5,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(8,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member9,(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),DATEADD(day,-95,@Today),11,5,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(9,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member10,(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),DATEADD(day,-95,@Today),12,6,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(10,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member11,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),DATEADD(day,-95,@Today),11,5,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(11,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member12,(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),DATEADD(day,-95,@Today),12,6,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(12,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member13,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),DATEADD(day,-95,@Today),16,10,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(13,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member14,(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),DATEADD(day,-95,@Today),17,11,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(14,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member15,(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),DATEADD(day,-95,@Today),14,8,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(15,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member16,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),DATEADD(day,-95,@Today),12,0,N'usedup');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(16,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member17,(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),DATEADD(day,-95,@Today),10,4,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(17,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member18,(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),DATEADD(day,-30,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(18,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member19,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),DATEADD(day,-5,@Today),10,10,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(19,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member20,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),DATEADD(day,-95,@Today),12,6,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(20,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member21,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),DATEADD(day,-95,@Today),16,10,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(21,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member22,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),DATEADD(day,-95,@Today),17,11,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(22,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member23,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),DATEADD(day,-95,@Today),14,8,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(23,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member24,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),DATEADD(day,-95,@Today),12,0,N'usedup');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(24,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member25,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),DATEADD(day,-95,@Today),10,4,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(25,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member26,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),DATEADD(day,-30,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(26,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member27,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),DATEADD(day,-5,@Today),10,10,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(27,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member28,(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-95,@Today),12,6,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(28,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member29,(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-95,@Today),16,10,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(29,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member30,(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-95,@Today),17,11,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(30,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member31,(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-95,@Today),14,8,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(31,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member32,(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-95,@Today),12,0,N'usedup');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(32,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member33,(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-95,@Today),10,4,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(33,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member34,(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-30,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(34,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member35,(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-5,@Today),10,10,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(35,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member36,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),DATEADD(day,-95,@Today),12,6,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(36,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member37,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),DATEADD(day,-95,@Today),16,10,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(37,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member38,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),DATEADD(day,-95,@Today),17,11,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(38,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member39,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),DATEADD(day,-95,@Today),14,8,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(39,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member40,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),DATEADD(day,-95,@Today),12,0,N'usedup');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(40,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member41,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),DATEADD(day,-95,@Today),10,4,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(41,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member42,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),DATEADD(day,-30,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(42,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member43,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),DATEADD(day,-5,@Today),10,10,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(43,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member44,(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),DATEADD(day,-95,@Today),16,10,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(44,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member45,(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),DATEADD(day,-95,@Today),17,11,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(45,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member46,(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),DATEADD(day,-95,@Today),14,8,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(46,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member47,(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),DATEADD(day,-95,@Today),12,0,N'usedup');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(47,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member48,(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),DATEADD(day,-95,@Today),10,4,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(48,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member49,(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),DATEADD(day,-30,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(49,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member50,(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),DATEADD(day,-5,@Today),10,10,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(50,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member18,(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),DATEADD(day,-2,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(51,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member15,(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),DATEADD(day,-4,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(52,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member15,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),DATEADD(day,-3,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(53,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member16,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),DATEADD(day,-4,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(54,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member17,(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),DATEADD(day,-6,@Today),12,11,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(55,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member15,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),DATEADD(day,-7,@Today),12,11,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(56,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member26,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),DATEADD(day,-2,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(57,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member23,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),DATEADD(day,-4,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(58,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member23,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),DATEADD(day,-3,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(59,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member24,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),DATEADD(day,-4,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(60,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member25,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),DATEADD(day,-6,@Today),12,11,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(61,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member34,(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-2,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(62,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member31,(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-4,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(63,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member31,(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-3,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(64,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member32,(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-4,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(65,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member33,(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-6,@Today),12,11,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(66,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member31,(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-7,@Today),12,11,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(67,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member42,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),DATEADD(day,-2,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(68,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member39,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),DATEADD(day,-4,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(69,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member39,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),DATEADD(day,-3,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(70,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member40,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),DATEADD(day,-4,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(71,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member41,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),DATEADD(day,-6,@Today),12,11,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(72,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member39,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),DATEADD(day,-7,@Today),12,11,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(73,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member49,(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),DATEADD(day,-2,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(74,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member46,(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),DATEADD(day,-4,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(75,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member46,(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),DATEADD(day,-3,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(76,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member47,(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),DATEADD(day,-4,@Today),12,12,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(77,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member48,(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),DATEADD(day,-6,@Today),12,11,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(78,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member46,(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),DATEADD(day,-7,@Today),12,11,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(79,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member16,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),DATEADD(day,-95,@Today),6,0,N'usedup');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(80,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member24,(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),DATEADD(day,-95,@Today),6,0,N'usedup');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(81,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member32,(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-95,@Today),6,0,N'usedup');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(82,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member40,(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),DATEADD(day,-95,@Today),6,0,N'usedup');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(83,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member47,(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),DATEADD(day,-95,@Today),6,0,N'usedup');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(84,@NewId);
INSERT INTO dbo.membercourse(memberid,courseid,coachid,purchasedate,totalsessions,remainingsessions,status) VALUES(@member2,(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),DATEADD(day,-7,@Today),12,11,N'active');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @PlanMap VALUES(85,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-37,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(1,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(1,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-37,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(1,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-30,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(2,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(2,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-30,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(2,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-23,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(3,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(3,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-23,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(3,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-16,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(4,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(4,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-16,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(4,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-9,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(5,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(5,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-9,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(5,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-2,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(6,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(6,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-2,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(6,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-48,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(7,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=2),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-48,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-48,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(7,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-48,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-48,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(7,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-41,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(8,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=2),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-41,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-41,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(8,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-41,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-41,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(8,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-34,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(9,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=2),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-34,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-34,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(9,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-34,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-34,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(9,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-27,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(10,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=2),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-27,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-27,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(10,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-27,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-27,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(10,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-20,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(11,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=2),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-20,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-20,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(11,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-20,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-20,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(11,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-13,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(12,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=2),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-13,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-13,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(12,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-13,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-13,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(12,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-37,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(13,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(13,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-37,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(13,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-30,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(14,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(14,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-30,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(14,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-23,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(15,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(15,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-23,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(15,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-16,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(16,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(16,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-16,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(16,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-9,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(17,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(17,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-9,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(17,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-2,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(18,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(18,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-2,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(18,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-37,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(19,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(19,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-37,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(19,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-30,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(20,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(20,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-30,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(20,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-23,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(21,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(21,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-23,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(21,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-16,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(22,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(22,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-16,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(22,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-9,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(23,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(23,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-9,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(23,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-2,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(24,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(24,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-2,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(24,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-37,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(25,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(25,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-37,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(25,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-30,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(26,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(26,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-30,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(26,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-23,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(27,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(27,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-23,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(27,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-16,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(28,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(28,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-16,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(28,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-9,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(29,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(29,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-9,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(29,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-2,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(30,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(30,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-2,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(30,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-37,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(31,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(31,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-37,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(31,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-30,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(32,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(32,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-30,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(32,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-23,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(33,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(33,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-23,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(33,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-16,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(34,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(34,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-16,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(34,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-9,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(35,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(35,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-9,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(35,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-2,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(36,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(36,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-2,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(36,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-48,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(37,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=7),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-48,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-48,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(37,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-48,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-48,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(37,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-41,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(38,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=7),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-41,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-41,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(38,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-41,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-41,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(38,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-34,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(39,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=7),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-34,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-34,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(39,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-34,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-34,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(39,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-27,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(40,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=7),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-27,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-27,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(40,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-27,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-27,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(40,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-20,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(41,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=7),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-20,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-20,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(41,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-20,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-20,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(41,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-13,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(42,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=7),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-13,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-13,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(42,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-13,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-13,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(42,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-48,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(43,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=8),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-48,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-48,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(43,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-48,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-48,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(43,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-41,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(44,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=8),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-41,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-41,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(44,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-41,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-41,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(44,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-34,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(45,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=8),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-34,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-34,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(45,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-34,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-34,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(45,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-27,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(46,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=8),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-27,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-27,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(46,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-27,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-27,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(46,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-20,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(47,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=8),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-20,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-20,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(47,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-20,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-20,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(47,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-13,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(48,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=8),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-13,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-13,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(48,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-13,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-13,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(48,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-48,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(49,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=9),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-48,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-48,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(49,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-48,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-48,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(49,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-41,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(50,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=9),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-41,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-41,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(50,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-41,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-41,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(50,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-34,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(51,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=9),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-34,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-34,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(51,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-34,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-34,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(51,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-27,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(52,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=9),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-27,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-27,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(52,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-27,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-27,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(52,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-20,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(53,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=9),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-20,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-20,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(53,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-20,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-20,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(53,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-13,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(54,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=9),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-13,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-13,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(54,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-13,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-13,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(54,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-49,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(55,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=10),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-49,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-49,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(55,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-49,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-49,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(55,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-42,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(56,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=10),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-42,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-42,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(56,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-42,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-42,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(56,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-35,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(57,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=10),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-35,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-35,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(57,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-35,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-35,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(57,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-28,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(58,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=10),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-28,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-28,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(58,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-28,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-28,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(58,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-21,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(59,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=10),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-21,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-21,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(59,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-21,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-21,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(59,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-14,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(60,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=10),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-14,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-14,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(60,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(minute,840,CAST(DATEADD(day,-1,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'補登：上課日與操作日不同',DATEADD(minute,840,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(60,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-48,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(61,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=11),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-48,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-48,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(61,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-48,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-48,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(61,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-41,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(62,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=11),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-41,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-41,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(62,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-41,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-41,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(62,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-34,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(63,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=11),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-34,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-34,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(63,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-34,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-34,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(63,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-27,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(64,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=11),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-27,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-27,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(64,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-27,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-27,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(64,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-20,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(65,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=11),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-20,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-20,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(65,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-20,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-20,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(65,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-13,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(66,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=11),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-13,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-13,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(66,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-13,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-13,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(66,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-49,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(67,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=12),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-49,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-49,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(67,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-49,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-49,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(67,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-42,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(68,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=12),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-42,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-42,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(68,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-42,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-42,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(68,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-35,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(69,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=12),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-35,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-35,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(69,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-35,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-35,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(69,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-28,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(70,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=12),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-28,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-28,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(70,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-28,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-28,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(70,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-21,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(71,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=12),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-21,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-21,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(71,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-21,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-21,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(71,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-14,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(72,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=12),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-14,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-14,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(72,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(minute,840,CAST(DATEADD(day,-1,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'補登：上課日與操作日不同',DATEADD(minute,840,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(72,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-59,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(73,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=13),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(73,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(73,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-52,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(74,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=13),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(74,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(74,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-45,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(75,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=13),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(75,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(75,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-38,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(76,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=13),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(76,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(76,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-31,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(77,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=13),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(77,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(77,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-24,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(78,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=13),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(78,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-24,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(78,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-37,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(79,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=14),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(79,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-37,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(79,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-30,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(80,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=14),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(80,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-30,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(80,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-23,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(81,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=14),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(81,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-23,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(81,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-16,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(82,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=14),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(82,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-16,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(82,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-9,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(83,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=14),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(83,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-9,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(83,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-2,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(84,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=14),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(84,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-2,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(84,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-59,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(85,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=15),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(85,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(85,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-52,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(86,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=15),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(86,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(86,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-45,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(87,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=15),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(87,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(87,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-38,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(88,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=15),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(88,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(88,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-31,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(89,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=15),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(89,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(89,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-24,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(90,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=15),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(90,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-24,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(90,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-87,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(91,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=16),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-87,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-87,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(91,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-87,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-87,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(91,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-80,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(92,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=16),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-80,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-80,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(92,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-80,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-80,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(92,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-73,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(93,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=16),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-73,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-73,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(93,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-73,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-73,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(93,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-66,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(94,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=16),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(94,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-66,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(94,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-59,@Today),N'10:00:00',N'11:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(95,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=16),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(95,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(95,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-52,@Today),N'10:00:00',N'11:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(96,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=16),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(96,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(96,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-45,@Today),N'10:00:00',N'11:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(97,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=16),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(97,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(97,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-38,@Today),N'10:00:00',N'11:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(98,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=16),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(98,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(98,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-31,@Today),N'10:00:00',N'11:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(99,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=16),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(99,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(99,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-24,@Today),N'10:00:00',N'11:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(100,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=16),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(100,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-24,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(100,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-17,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(101,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=16),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-17,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-17,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(101,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-17,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-17,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(101,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-10,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(102,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=16),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-10,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-10,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(102,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-10,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-10,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(102,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-65,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(103,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=17),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-65,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-65,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(103,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-65,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-65,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(103,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-58,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(104,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=17),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-58,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-58,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(104,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-58,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-58,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(104,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-51,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(105,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=17),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-51,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-51,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(105,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-51,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-51,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(105,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-44,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(106,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=17),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(106,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-44,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(106,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-37,@Today),N'10:00:00',N'11:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(107,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=17),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(107,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-37,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(107,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-30,@Today),N'10:00:00',N'11:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(108,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=17),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(108,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-30,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(108,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-49,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(109,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=20),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-49,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-49,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(109,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-49,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-49,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(109,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-42,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(110,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=20),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-42,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-42,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(110,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-42,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-42,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(110,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-35,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(111,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=20),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-35,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-35,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(111,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-35,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-35,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(111,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-28,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(112,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=20),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-28,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-28,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(112,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-28,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-28,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(112,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-21,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(113,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=20),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-21,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-21,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(113,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-21,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-21,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(113,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-14,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(114,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=20),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-14,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-14,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(114,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(minute,840,CAST(DATEADD(day,-1,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'補登：上課日與操作日不同',DATEADD(minute,840,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(114,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-59,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(115,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=21),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(115,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(115,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-52,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(116,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=21),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(116,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(116,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-45,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(117,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=21),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(117,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(117,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-38,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(118,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=21),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(118,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(118,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-31,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(119,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=21),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(119,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(119,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-24,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(120,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=21),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(120,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-24,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(120,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-37,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(121,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=22),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(121,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-37,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(121,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-30,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(122,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=22),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(122,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-30,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(122,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-23,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(123,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=22),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(123,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-23,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(123,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-16,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(124,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=22),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(124,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-16,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(124,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-9,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(125,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=22),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(125,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-9,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(125,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-2,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(126,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=22),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(126,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-2,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(126,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-59,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(127,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=23),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(127,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(127,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-52,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(128,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=23),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(128,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(128,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-45,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(129,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=23),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(129,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(129,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-38,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(130,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=23),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(130,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(130,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-31,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(131,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=23),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(131,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(131,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-24,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(132,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=23),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(132,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-24,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(132,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-87,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(133,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=24),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-87,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-87,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(133,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-87,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-87,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(133,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-80,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(134,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=24),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-80,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-80,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(134,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-80,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-80,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(134,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-73,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(135,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=24),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-73,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-73,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(135,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-73,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-73,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(135,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-66,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(136,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=24),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(136,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-66,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(136,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-59,@Today),N'10:00:00',N'11:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(137,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=24),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(137,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(137,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-52,@Today),N'10:00:00',N'11:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(138,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=24),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(138,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(138,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-45,@Today),N'10:00:00',N'11:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(139,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=24),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(139,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(139,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-38,@Today),N'10:00:00',N'11:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(140,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=24),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(140,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(140,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-31,@Today),N'10:00:00',N'11:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(141,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=24),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(141,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(141,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-24,@Today),N'10:00:00',N'11:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(142,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=24),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(142,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-24,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(142,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-17,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(143,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=24),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-17,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-17,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(143,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-17,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-17,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(143,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-10,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(144,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=24),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-10,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-10,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(144,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-10,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-10,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(144,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-65,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(145,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=25),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-65,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-65,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(145,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-65,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-65,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(145,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-58,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(146,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=25),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-58,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-58,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(146,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-58,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-58,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(146,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-51,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(147,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=25),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-51,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-51,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(147,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-51,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-51,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(147,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-44,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(148,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=25),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(148,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-44,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(148,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-37,@Today),N'10:00:00',N'11:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(149,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=25),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(149,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-37,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(149,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-30,@Today),N'10:00:00',N'11:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(150,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=25),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(150,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-30,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(150,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-49,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(151,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=28),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-49,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-49,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(151,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-49,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-49,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(151,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-42,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(152,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=28),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-42,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-42,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(152,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-42,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-42,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(152,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-35,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(153,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=28),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-35,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-35,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(153,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-35,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-35,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(153,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-28,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(154,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=28),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-28,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-28,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(154,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-28,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-28,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(154,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-21,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(155,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=28),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-21,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-21,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(155,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-21,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-21,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(155,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-14,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(156,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=28),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-14,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-14,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(156,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(minute,840,CAST(DATEADD(day,-1,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'補登：上課日與操作日不同',DATEADD(minute,840,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(156,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-59,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(157,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=29),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(157,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(157,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-52,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(158,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=29),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(158,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(158,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-45,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(159,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=29),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(159,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(159,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-38,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(160,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=29),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(160,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(160,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-31,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(161,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=29),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(161,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(161,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-24,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(162,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=29),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(162,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-24,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(162,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-37,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(163,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=30),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(163,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-37,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(163,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-30,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(164,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=30),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(164,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-30,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(164,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-23,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(165,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=30),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(165,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-23,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(165,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-16,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(166,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=30),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(166,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-16,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(166,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-9,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(167,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=30),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(167,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-9,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(167,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-2,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(168,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=30),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(168,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-2,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(168,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-59,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(169,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=31),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(169,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(169,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-52,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(170,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=31),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(170,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(170,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-45,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(171,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=31),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(171,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(171,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-38,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(172,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=31),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(172,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(172,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-31,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(173,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=31),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(173,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(173,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-24,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(174,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=31),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(174,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-24,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(174,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-87,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(175,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=32),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-87,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-87,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(175,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-87,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-87,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(175,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-80,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(176,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=32),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-80,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-80,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(176,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-80,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-80,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(176,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-73,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(177,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=32),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-73,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-73,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(177,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-73,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-73,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(177,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-66,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(178,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=32),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(178,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-66,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(178,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-59,@Today),N'10:00:00',N'11:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(179,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=32),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(179,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(179,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-52,@Today),N'10:00:00',N'11:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(180,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=32),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(180,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(180,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-45,@Today),N'10:00:00',N'11:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(181,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=32),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(181,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(181,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-38,@Today),N'10:00:00',N'11:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(182,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=32),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(182,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(182,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-31,@Today),N'10:00:00',N'11:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(183,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=32),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(183,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(183,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-24,@Today),N'10:00:00',N'11:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(184,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=32),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(184,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-24,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(184,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-17,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(185,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=32),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-17,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-17,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(185,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-17,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-17,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(185,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-10,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(186,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=32),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-10,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-10,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(186,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-10,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-10,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(186,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-65,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(187,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=33),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-65,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-65,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(187,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-65,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-65,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(187,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-58,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(188,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=33),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-58,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-58,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(188,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-58,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-58,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(188,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-51,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(189,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=33),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-51,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-51,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(189,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-51,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-51,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(189,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-44,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(190,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=33),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(190,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-44,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(190,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-37,@Today),N'10:00:00',N'11:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(191,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=33),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(191,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-37,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(191,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-30,@Today),N'10:00:00',N'11:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(192,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=33),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(192,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-30,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(192,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-49,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(193,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=36),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-49,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-49,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(193,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-49,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-49,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(193,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-42,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(194,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=36),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-42,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-42,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(194,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-42,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-42,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(194,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-35,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(195,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=36),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-35,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-35,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(195,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-35,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-35,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(195,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-28,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(196,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=36),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-28,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-28,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(196,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-28,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-28,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(196,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-21,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(197,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=36),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-21,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-21,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(197,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-21,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-21,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(197,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-14,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(198,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=36),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-14,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-14,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(198,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(minute,840,CAST(DATEADD(day,-1,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'補登：上課日與操作日不同',DATEADD(minute,840,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(198,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-59,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(199,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=37),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(199,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(199,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-52,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(200,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=37),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(200,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(200,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-45,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(201,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=37),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(201,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(201,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-38,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(202,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=37),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(202,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(202,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-31,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(203,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=37),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(203,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(203,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-24,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(204,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=37),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(204,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-24,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(204,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-37,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(205,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=38),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(205,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-37,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(205,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-30,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(206,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=38),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(206,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-30,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(206,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-23,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(207,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=38),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(207,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-23,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(207,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-16,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(208,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=38),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(208,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-16,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(208,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-9,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(209,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=38),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(209,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-9,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(209,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-2,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(210,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=38),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(210,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-2,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(210,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-59,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(211,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=39),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(211,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(211,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-52,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(212,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=39),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(212,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(212,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-45,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(213,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=39),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(213,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(213,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-38,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(214,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=39),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(214,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(214,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-31,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(215,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=39),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(215,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(215,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-24,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(216,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=39),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(216,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-24,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(216,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-87,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(217,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=40),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-87,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-87,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(217,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-87,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-87,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(217,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-80,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(218,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=40),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-80,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-80,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(218,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-80,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-80,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(218,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-73,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(219,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=40),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-73,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-73,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(219,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-73,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-73,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(219,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-66,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(220,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=40),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(220,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-66,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(220,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-59,@Today),N'10:00:00',N'11:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(221,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=40),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(221,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(221,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-52,@Today),N'10:00:00',N'11:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(222,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=40),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(222,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(222,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-45,@Today),N'10:00:00',N'11:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(223,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=40),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(223,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(223,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-38,@Today),N'10:00:00',N'11:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(224,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=40),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(224,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(224,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-31,@Today),N'10:00:00',N'11:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(225,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=40),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(225,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(225,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-24,@Today),N'10:00:00',N'11:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(226,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=40),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(226,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-24,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(226,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-17,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(227,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=40),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-17,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-17,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(227,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-17,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-17,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(227,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-10,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(228,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=40),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-10,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-10,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(228,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-10,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-10,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(228,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-65,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(229,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=41),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-65,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-65,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(229,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-65,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-65,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(229,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-58,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(230,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=41),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-58,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-58,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(230,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-58,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-58,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(230,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-51,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(231,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=41),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-51,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-51,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(231,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-51,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-51,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(231,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-44,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(232,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=41),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(232,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-44,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(232,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-37,@Today),N'10:00:00',N'11:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(233,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=41),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(233,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-37,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(233,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-30,@Today),N'10:00:00',N'11:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(234,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=41),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(234,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-30,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(234,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-59,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(235,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=44),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(235,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(235,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-52,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(236,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=44),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(236,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(236,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-45,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(237,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=44),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(237,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(237,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-38,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(238,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=44),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(238,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(238,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-31,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(239,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=44),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(239,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(239,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-24,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(240,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=44),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(240,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-24,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(240,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-37,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(241,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=45),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(241,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-37,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(241,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-30,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(242,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=45),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(242,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-30,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(242,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-23,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(243,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=45),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(243,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-23,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-23,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(243,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-16,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(244,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=45),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(244,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-16,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-16,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(244,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-9,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(245,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=45),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(245,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-9,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-9,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(245,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-2,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(246,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=45),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(246,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-2,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-2,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(246,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-59,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(247,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=46),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(247,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(247,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-52,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(248,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=46),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(248,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(248,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-45,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(249,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=46),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(249,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(249,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-38,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(250,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=46),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(250,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(250,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-31,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(251,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=46),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(251,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(251,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-24,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(252,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=46),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(252,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-24,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(252,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-87,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(253,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=47),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-87,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-87,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(253,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-87,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-87,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(253,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-80,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(254,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=47),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-80,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-80,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(254,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-80,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-80,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(254,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-73,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(255,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=47),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-73,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-73,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(255,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-73,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-73,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(255,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-66,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(256,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=47),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(256,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-66,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(256,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-59,@Today),N'10:00:00',N'11:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(257,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=47),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(257,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(257,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-52,@Today),N'10:00:00',N'11:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(258,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=47),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(258,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(258,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-45,@Today),N'10:00:00',N'11:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(259,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=47),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(259,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(259,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-38,@Today),N'10:00:00',N'11:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(260,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=47),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(260,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(260,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-31,@Today),N'10:00:00',N'11:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(261,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=47),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(261,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(261,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-24,@Today),N'10:00:00',N'11:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(262,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=47),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(262,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-24,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-24,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(262,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-17,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(263,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=47),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-17,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-17,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(263,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-17,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-17,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(263,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-10,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(264,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=47),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-10,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-10,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(264,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-10,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-10,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(264,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-65,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(265,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=48),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-65,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-65,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(265,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-65,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-65,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(265,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-58,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(266,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=48),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-58,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-58,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(266,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-58,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-58,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(266,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-51,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(267,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=48),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-51,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-51,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(267,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-51,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-51,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(267,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-44,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(268,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=48),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(268,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-44,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(268,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-37,@Today),N'10:00:00',N'11:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(269,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=48),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(269,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-37,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-37,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(269,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-30,@Today),N'10:00:00',N'11:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(270,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=48),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(270,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-30,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-30,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(270,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-3,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(271,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=55),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(271,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-3,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(271,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-3,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(272,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=56),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(272,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-3,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(272,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-3,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(273,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=61),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(273,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-3,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(273,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-3,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(274,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=66),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(274,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-3,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(274,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-3,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(275,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=67),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(275,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-3,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(275,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-3,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(276,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=72),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(276,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-3,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(276,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-3,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(277,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=73),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(277,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-3,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(277,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-3,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(278,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=78),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(278,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(DATEADD(day,-3,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,8,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(278,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-3,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(279,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=79),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(279,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-3,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(279,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-66,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(280,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=80),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(280,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-66,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(280,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-59,@Today),N'11:00:00',N'12:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(281,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=80),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(281,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(281,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-52,@Today),N'11:00:00',N'12:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(282,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=80),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(282,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(282,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-45,@Today),N'11:00:00',N'12:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(283,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=80),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(283,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(283,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-38,@Today),N'11:00:00',N'12:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(284,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=80),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(284,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(284,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-31,@Today),N'11:00:00',N'12:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(285,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=80),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(285,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(285,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-66,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(286,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=81),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(286,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-66,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(286,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-59,@Today),N'11:00:00',N'12:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(287,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=81),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(287,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(287,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-52,@Today),N'11:00:00',N'12:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(288,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=81),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(288,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(288,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-45,@Today),N'11:00:00',N'12:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(289,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=81),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(289,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(289,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-38,@Today),N'11:00:00',N'12:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(290,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=81),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(290,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(290,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-31,@Today),N'11:00:00',N'12:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(291,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=81),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(291,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(291,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-66,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(292,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=82),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(292,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-66,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(292,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-59,@Today),N'11:00:00',N'12:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(293,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=82),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(293,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(293,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-52,@Today),N'11:00:00',N'12:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(294,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=82),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(294,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(294,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-45,@Today),N'11:00:00',N'12:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(295,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=82),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(295,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(295,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-38,@Today),N'11:00:00',N'12:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(296,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=82),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(296,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(296,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-31,@Today),N'11:00:00',N'12:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(297,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=82),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(297,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(297,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-66,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(298,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=83),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(298,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-66,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(298,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-59,@Today),N'11:00:00',N'12:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(299,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=83),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(299,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(299,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-52,@Today),N'11:00:00',N'12:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(300,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=83),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(300,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(300,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-45,@Today),N'11:00:00',N'12:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(301,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=83),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(301,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(301,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-38,@Today),N'11:00:00',N'12:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(302,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=83),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(302,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(302,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-31,@Today),N'11:00:00',N'12:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(303,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=83),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(303,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(303,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-66,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(304,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=84),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(304,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,9,CAST(DATEADD(day,-66,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,9,CAST(DATEADD(day,-66,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(304,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-59,@Today),N'11:00:00',N'12:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(305,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=84),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(305,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-59,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-59,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(305,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-52,@Today),N'11:00:00',N'12:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(306,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=84),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(306,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-52,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-52,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(306,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-45,@Today),N'11:00:00',N'12:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(307,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=84),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(307,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-45,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(307,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-38,@Today),N'11:00:00',N'12:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(308,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=84),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(308,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-38,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-38,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(308,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-31,@Today),N'11:00:00',N'12:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(309,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=84),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(309,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,11,CAST(DATEADD(day,-31,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,11,CAST(DATEADD(day,-31,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(309,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-3,@Today),N'10:00:00',N'11:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(310,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=85),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)),N'booked',N'歷史已出席',DATEADD(day,-2,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(310,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,10,CAST(DATEADD(day,-3,@Today) AS datetime)),N'PRESENT',N'核心與肌力',N'歷史已出席',DATEADD(hour,10,CAST(DATEADD(day,-3,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(310,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),@ShowDate,N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(311,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(311,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(@ShowDate AS datetime)),N'PRESENT',N'核心與肌力',N'完整展示日',DATEADD(hour,8,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(311,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),@ShowDate,N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(312,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=2),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(312,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'PENDING',NULL,N'完整展示日',NULL);
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(312,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),@ShowDate,N'10:00:00',N'11:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(313,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=10),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(313,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),@ShowDate,N'11:00:00',N'12:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(314,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=13),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(314,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'完整展示日',DATEADD(hour,11,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(314,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),@ShowDate,N'12:00:00',N'13:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(315,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=14),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(315,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'完整展示日',DATEADD(hour,12,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(315,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),@ShowDate,N'13:00:00',N'14:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(316,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=15),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'cancelled',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(316,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,0,@Today),N'19:00:00',N'20:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(317,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),@NewId,DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)),N'booked',N'今天剩一堂待確認',DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(317,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,0,@Today),N'20:00:00',N'21:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(318,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=2),@NewId,DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)),N'booked',N'今天已有待確認',DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(318,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'PENDING',NULL,N'今天已有待確認',NULL);
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(318,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-45,@Today),N'12:00:00',N'13:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(319,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(319,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,12,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(319,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-44,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(320,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(320,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,9,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(320,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-43,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(321,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(321,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-45,@Today),N'13:00:00',N'14:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(322,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=13),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(322,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,13,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(322,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-44,@Today),N'10:00:00',N'11:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(323,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=13),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(323,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,10,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(323,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-43,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(324,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=13),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(324,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-45,@Today),N'14:00:00',N'15:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(325,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=14),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(325,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,14,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(325,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-44,@Today),N'11:00:00',N'12:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(326,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=14),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(326,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,11,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(326,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-43,@Today),N'10:00:00',N'11:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(327,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=14),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(327,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-45,@Today),N'15:00:00',N'16:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(328,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=16),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(328,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,15,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(328,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-44,@Today),N'12:00:00',N'13:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(329,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=16),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(329,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,12,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(329,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-43,@Today),N'11:00:00',N'12:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(330,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=16),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(330,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,1,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(331,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,1,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(332,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,2,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(333,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,2,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(334,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,2,@Today),N'10:00:00',N'11:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(335,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=2),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'booked',N'未來可取消/改期預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(335,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,3,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(336,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,3,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(337,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,4,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(338,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,4,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(339,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,5,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(340,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,5,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(341,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,6,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(342,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,6,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(343,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,6,@Today),N'10:00:00',N'11:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(344,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=2),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'booked',N'未來可取消/改期預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(344,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,7,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(345,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,7,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(346,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,8,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(347,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,8,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(348,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,9,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(349,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,9,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(350,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,10,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(351,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,10,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(352,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,10,@Today),N'10:00:00',N'11:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(353,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=2),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'booked',N'未來可取消/改期預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(353,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,11,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(354,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,11,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(355,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,12,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(356,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,12,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(357,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,13,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(358,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,13,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(359,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,14,@Today),N'08:00:00',N'09:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(360,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,14,@Today),N'09:00:00',N'10:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(361,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,3,@Today),N'11:00:00',N'12:00:00',N'教室1',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(362,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'cancelled',N'取消後可重新預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(362,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),@ShowDate,N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(363,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(363,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(@ShowDate AS datetime)),N'PRESENT',N'核心與肌力',N'完整展示日',DATEADD(hour,8,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(363,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),@ShowDate,N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(364,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=11),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(364,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'PENDING',NULL,N'完整展示日',NULL);
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(364,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),@ShowDate,N'10:00:00',N'11:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(365,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=20),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(365,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),@ShowDate,N'11:00:00',N'12:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(366,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=21),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(366,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'完整展示日',DATEADD(hour,11,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(366,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),@ShowDate,N'12:00:00',N'13:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(367,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=22),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(367,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'完整展示日',DATEADD(hour,12,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(367,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),@ShowDate,N'13:00:00',N'14:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(368,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=23),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'cancelled',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(368,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,0,@Today),N'19:00:00',N'20:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(369,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),@NewId,DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)),N'booked',N'今天剩一堂待確認',DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(369,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,0,@Today),N'20:00:00',N'21:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(370,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=11),@NewId,DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)),N'booked',N'今天已有待確認',DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(370,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'PENDING',NULL,N'今天已有待確認',NULL);
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(370,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-45,@Today),N'12:00:00',N'13:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(371,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(371,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,12,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(371,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-44,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(372,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(372,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,9,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(372,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-43,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(373,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(373,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-45,@Today),N'13:00:00',N'14:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(374,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=21),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(374,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,13,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(374,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-44,@Today),N'10:00:00',N'11:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(375,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=21),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(375,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,10,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(375,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-43,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(376,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=21),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(376,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-45,@Today),N'14:00:00',N'15:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(377,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=22),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(377,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,14,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(377,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-44,@Today),N'11:00:00',N'12:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(378,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=22),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(378,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,11,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(378,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-43,@Today),N'10:00:00',N'11:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(379,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=22),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(379,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-45,@Today),N'15:00:00',N'16:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(380,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=24),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(380,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,15,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(380,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-44,@Today),N'12:00:00',N'13:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(381,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=24),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(381,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,12,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(381,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-43,@Today),N'11:00:00',N'12:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(382,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=24),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(382,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,1,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(383,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,1,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(384,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,2,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(385,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,2,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(386,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,2,@Today),N'10:00:00',N'11:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(387,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=11),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'booked',N'未來可取消/改期預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(387,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,3,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(388,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,3,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(389,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,4,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(390,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,4,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(391,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,5,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(392,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,5,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(393,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,6,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(394,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,6,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(395,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,6,@Today),N'10:00:00',N'11:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(396,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=11),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'booked',N'未來可取消/改期預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(396,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,7,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(397,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,7,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(398,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,8,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(399,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,8,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(400,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,9,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(401,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,9,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(402,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,10,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(403,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,10,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(404,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,10,@Today),N'10:00:00',N'11:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(405,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=11),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'booked',N'未來可取消/改期預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(405,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,11,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(406,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,11,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(407,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,12,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(408,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,12,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(409,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,13,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(410,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,13,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(411,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,14,@Today),N'08:00:00',N'09:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(412,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,14,@Today),N'09:00:00',N'10:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(413,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,3,@Today),N'11:00:00',N'12:00:00',N'教室2',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(414,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'cancelled',N'取消後可重新預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(414,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),@ShowDate,N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(415,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(415,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(@ShowDate AS datetime)),N'PRESENT',N'核心與肌力',N'完整展示日',DATEADD(hour,8,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(415,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),@ShowDate,N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(416,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=8),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(416,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'PENDING',NULL,N'完整展示日',NULL);
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(416,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),@ShowDate,N'10:00:00',N'11:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(417,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=28),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(417,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),@ShowDate,N'11:00:00',N'12:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(418,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=29),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(418,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'完整展示日',DATEADD(hour,11,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(418,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),@ShowDate,N'12:00:00',N'13:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(419,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=30),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(419,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'完整展示日',DATEADD(hour,12,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(419,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),@ShowDate,N'13:00:00',N'14:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(420,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=31),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'cancelled',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(420,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,0,@Today),N'19:00:00',N'20:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(421,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),@NewId,DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)),N'booked',N'今天剩一堂待確認',DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(421,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,0,@Today),N'20:00:00',N'21:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(422,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=8),@NewId,DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)),N'booked',N'今天已有待確認',DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(422,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'PENDING',NULL,N'今天已有待確認',NULL);
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(422,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-45,@Today),N'12:00:00',N'13:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(423,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(423,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,12,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(423,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-44,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(424,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(424,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,9,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(424,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-43,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(425,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(425,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-45,@Today),N'13:00:00',N'14:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(426,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=29),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(426,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,13,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(426,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-44,@Today),N'10:00:00',N'11:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(427,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=29),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(427,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,10,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(427,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-43,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(428,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=29),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(428,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-45,@Today),N'14:00:00',N'15:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(429,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=30),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(429,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,14,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(429,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-44,@Today),N'11:00:00',N'12:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(430,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=30),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(430,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,11,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(430,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-43,@Today),N'10:00:00',N'11:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(431,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=30),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(431,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-45,@Today),N'15:00:00',N'16:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(432,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=32),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(432,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,15,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(432,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-44,@Today),N'12:00:00',N'13:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(433,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=32),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(433,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,12,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(433,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,-43,@Today),N'11:00:00',N'12:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(434,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=32),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(434,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,1,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(435,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,1,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(436,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,2,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(437,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,2,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(438,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,2,@Today),N'10:00:00',N'11:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(439,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=8),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'booked',N'未來可取消/改期預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(439,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,3,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(440,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,3,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(441,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,4,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(442,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,4,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(443,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,5,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(444,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,5,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(445,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,6,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(446,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,6,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(447,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,6,@Today),N'10:00:00',N'11:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(448,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=8),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'booked',N'未來可取消/改期預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(448,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,7,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(449,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,7,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(450,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,8,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(451,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,8,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(452,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,9,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(453,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,9,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(454,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,10,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(455,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,10,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(456,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'中階重訓'),DATEADD(day,10,@Today),N'10:00:00',N'11:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(457,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=8),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'booked',N'未來可取消/改期預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(457,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,11,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(458,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,11,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(459,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,12,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(460,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,12,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(461,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,13,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(462,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,13,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(463,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,14,@Today),N'08:00:00',N'09:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(464,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,14,@Today),N'09:00:00',N'10:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(465,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,3,@Today),N'11:00:00',N'12:00:00',N'教室3',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(466,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'cancelled',N'取消後可重新預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(466,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),@ShowDate,N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(467,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(467,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(@ShowDate AS datetime)),N'PRESENT',N'核心與肌力',N'完整展示日',DATEADD(hour,8,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(467,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),@ShowDate,N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(468,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=7),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(468,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'PENDING',NULL,N'完整展示日',NULL);
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(468,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),@ShowDate,N'10:00:00',N'11:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(469,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=36),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(469,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),@ShowDate,N'11:00:00',N'12:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(470,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=37),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(470,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'完整展示日',DATEADD(hour,11,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(470,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),@ShowDate,N'12:00:00',N'13:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(471,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=38),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(471,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'完整展示日',DATEADD(hour,12,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(471,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),@ShowDate,N'13:00:00',N'14:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(472,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=39),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'cancelled',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(472,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,0,@Today),N'19:00:00',N'20:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(473,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),@NewId,DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)),N'booked',N'今天剩一堂待確認',DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(473,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,0,@Today),N'20:00:00',N'21:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(474,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=7),@NewId,DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)),N'booked',N'今天已有待確認',DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(474,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'PENDING',NULL,N'今天已有待確認',NULL);
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(474,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-45,@Today),N'12:00:00',N'13:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(475,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(475,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,12,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(475,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-44,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(476,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(476,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,9,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(476,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-43,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(477,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(477,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-45,@Today),N'13:00:00',N'14:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(478,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=37),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(478,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,13,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(478,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-44,@Today),N'10:00:00',N'11:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(479,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=37),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(479,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,10,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(479,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,-43,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(480,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=37),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(480,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-45,@Today),N'14:00:00',N'15:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(481,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=38),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(481,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,14,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(481,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-44,@Today),N'11:00:00',N'12:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(482,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=38),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(482,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,11,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(482,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-43,@Today),N'10:00:00',N'11:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(483,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=38),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(483,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-45,@Today),N'15:00:00',N'16:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(484,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=40),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(484,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,15,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(484,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-44,@Today),N'12:00:00',N'13:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(485,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=40),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(485,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,12,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(485,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,-43,@Today),N'11:00:00',N'12:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(486,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=40),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(486,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,1,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(487,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,1,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(488,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,2,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(489,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,2,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(490,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,2,@Today),N'10:00:00',N'11:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(491,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=7),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'booked',N'未來可取消/改期預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(491,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,3,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(492,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,3,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(493,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,4,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(494,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,4,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(495,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,5,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(496,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,5,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(497,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,6,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(498,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,6,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(499,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,6,@Today),N'10:00:00',N'11:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(500,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=7),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'booked',N'未來可取消/改期預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(500,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,7,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(501,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,7,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(502,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,8,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(503,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,8,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(504,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,9,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(505,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,9,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(506,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,10,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(507,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,10,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(508,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'筋膜放鬆'),DATEADD(day,10,@Today),N'10:00:00',N'11:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(509,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=7),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'booked',N'未來可取消/改期預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(509,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,11,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(510,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,11,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(511,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,12,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(512,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,12,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(513,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,13,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(514,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,13,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(515,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,14,@Today),N'08:00:00',N'09:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(516,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,14,@Today),N'09:00:00',N'10:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(517,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),(SELECT courseid FROM dbo.course WHERE coursename=N'初階重訓'),DATEADD(day,3,@Today),N'11:00:00',N'12:00:00',N'教室4',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(518,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'cancelled',N'取消後可重新預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(518,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),@ShowDate,N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(519,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(519,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,DATEADD(hour,8,CAST(@ShowDate AS datetime)),N'PRESENT',N'核心與肌力',N'完整展示日',DATEADD(hour,8,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(519,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),@ShowDate,N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(520,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=9),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(520,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'PENDING',NULL,N'完整展示日',NULL);
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(520,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),@ShowDate,N'10:00:00',N'11:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(521,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=12),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(521,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),@ShowDate,N'11:00:00',N'12:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(522,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=44),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(522,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'完整展示日',DATEADD(hour,11,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(522,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),@ShowDate,N'12:00:00',N'13:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(523,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=45),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'booked',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(523,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'完整展示日',DATEADD(hour,12,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(523,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),@ShowDate,N'13:00:00',N'14:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(524,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=46),@NewId,DATEADD(day,-2,CAST(@ShowDate AS datetime)),N'cancelled',N'完整展示日',DATEADD(day,-2,CAST(@ShowDate AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(524,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,0,@Today),N'19:00:00',N'20:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(525,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),@NewId,DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)),N'booked',N'今天剩一堂待確認',DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(525,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,0,@Today),N'20:00:00',N'21:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(526,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=9),@NewId,DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)),N'booked',N'今天已有待確認',DATEADD(day,-2,CAST(DATEADD(day,0,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(526,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'PENDING',NULL,N'今天已有待確認',NULL);
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(526,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-45,@Today),N'12:00:00',N'13:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(527,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(527,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,12,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(527,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-44,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(528,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(528,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,9,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(528,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-43,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(529,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(529,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-45,@Today),N'13:00:00',N'14:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(530,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=44),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(530,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,13,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(530,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-44,@Today),N'10:00:00',N'11:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(531,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=44),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(531,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,10,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(531,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,-43,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(532,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=44),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(532,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-45,@Today),N'14:00:00',N'15:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(533,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=45),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(533,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,14,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(533,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-44,@Today),N'11:00:00',N'12:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(534,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=45),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(534,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,11,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(534,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-43,@Today),N'10:00:00',N'11:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(535,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=45),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(535,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-45,@Today),N'15:00:00',N'16:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(536,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=47),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(536,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'LEAVE',NULL,N'歷史非出席',DATEADD(hour,15,CAST(DATEADD(day,-45,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(536,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-44,@Today),N'12:00:00',N'13:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(537,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=47),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)),N'booked',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(537,@NewId);
INSERT INTO dbo.attendance(bookingid,checkintime,attendancestatus,workoutfocus,note,updatetime) VALUES(@NewId,NULL,N'ABSENT',NULL,N'歷史非出席',DATEADD(hour,12,CAST(DATEADD(day,-44,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @AttendanceMap VALUES(537,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,-43,@Today),N'11:00:00',N'12:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(538,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=47),@NewId,DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)),N'cancelled',N'歷史非出席',DATEADD(day,-2,CAST(DATEADD(day,-43,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(538,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,1,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(539,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,1,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(540,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,2,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(541,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,2,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(542,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,2,@Today),N'10:00:00',N'11:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(543,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=9),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'booked',N'未來可取消/改期預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(543,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,3,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(544,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,3,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(545,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,4,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(546,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,4,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(547,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,5,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(548,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,5,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(549,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,6,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(550,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,6,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(551,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,6,@Today),N'10:00:00',N'11:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(552,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=9),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'booked',N'未來可取消/改期預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(552,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,7,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(553,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,7,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(554,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,8,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(555,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,8,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(556,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,9,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(557,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,9,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(558,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,10,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(559,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,10,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(560,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'高階重訓'),DATEADD(day,10,@Today),N'10:00:00',N'11:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(561,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=9),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'booked',N'未來可取消/改期預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(561,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,11,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(562,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,11,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(563,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,12,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(564,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,12,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(565,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,13,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(566,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,13,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(567,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,14,@Today),N'08:00:00',N'09:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(568,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,14,@Today),N'09:00:00',N'10:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(569,@NewId);
INSERT INTO dbo.classschedule(coachid,courseid,classdate,starttime,endtime,classroom,status) VALUES((SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),(SELECT courseid FROM dbo.course WHERE coursename=N'TRX'),DATEADD(day,3,@Today),N'11:00:00',N'12:00:00',N'教室5',N'open');
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @ScheduleMap VALUES(570,@NewId);
INSERT INTO dbo.booking(membercourseid,scheduleid,bookingtime,bookingstatus,note,updatetime) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),@NewId,DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)),N'cancelled',N'取消後可重新預約',DATEADD(minute,720,CAST(DATEADD(day,-1,@Today) AS datetime)));
SET @NewId=CONVERT(int,SCOPE_IDENTITY()); INSERT INTO @BookingMap VALUES(570,@NewId);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=1),@member1,DATEADD(day,-37,@Today),61.0,27.0,24.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=2),@member1,DATEADD(day,-30,@Today),60.57,26.7,24.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=3),@member1,DATEADD(day,-23,@Today),60.14,26.4,24.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=4),@member1,DATEADD(day,-16,@Today),59.71,26.1,24.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=5),@member1,DATEADD(day,-9,@Today),59.28,25.8,24.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=6),@member1,DATEADD(day,-2,@Today),58.85,25.5,25.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=7),@member2,DATEADD(day,-48,@Today),62.0,28.0,25.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=8),@member2,DATEADD(day,-41,@Today),61.57,27.7,25.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=9),@member2,DATEADD(day,-34,@Today),61.14,27.4,25.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=10),@member2,DATEADD(day,-27,@Today),60.71,27.1,25.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=11),@member2,DATEADD(day,-20,@Today),60.28,26.8,25.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=13),@member3,DATEADD(day,-37,@Today),63.0,29.0,26.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=14),@member3,DATEADD(day,-30,@Today),62.57,28.7,26.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=15),@member3,DATEADD(day,-23,@Today),62.14,28.4,26.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=16),@member3,DATEADD(day,-16,@Today),61.71,28.1,26.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=17),@member3,DATEADD(day,-9,@Today),61.28,27.8,26.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=18),@member3,DATEADD(day,-2,@Today),60.85,27.5,27.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=19),@member4,DATEADD(day,-37,@Today),64.0,30.0,27.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=20),@member4,DATEADD(day,-30,@Today),63.57,29.7,27.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=21),@member4,DATEADD(day,-23,@Today),63.14,29.4,27.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=22),@member4,DATEADD(day,-16,@Today),62.71,29.1,27.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=23),@member4,DATEADD(day,-9,@Today),62.28,28.8,27.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=24),@member4,DATEADD(day,-2,@Today),61.85,28.5,28.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=25),@member5,DATEADD(day,-37,@Today),65.0,31.0,28.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=26),@member5,DATEADD(day,-30,@Today),64.57,30.7,28.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=27),@member5,DATEADD(day,-23,@Today),64.14,30.4,28.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=28),@member5,DATEADD(day,-16,@Today),63.71,30.1,28.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=29),@member5,DATEADD(day,-9,@Today),63.28,29.8,28.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=30),@member5,DATEADD(day,-2,@Today),62.85,29.5,29.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=31),@member6,DATEADD(day,-37,@Today),66.0,26.0,29.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=32),@member6,DATEADD(day,-30,@Today),65.57,25.7,29.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=33),@member6,DATEADD(day,-23,@Today),65.14,25.4,29.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=34),@member6,DATEADD(day,-16,@Today),64.71,25.1,29.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=35),@member6,DATEADD(day,-9,@Today),64.28,24.8,29.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=36),@member6,DATEADD(day,-2,@Today),63.85,24.5,30.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=37),@member7,DATEADD(day,-48,@Today),67.0,27.0,30.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=38),@member7,DATEADD(day,-41,@Today),66.57,26.7,30.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=39),@member7,DATEADD(day,-34,@Today),66.14,26.4,30.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=40),@member7,DATEADD(day,-27,@Today),65.71,26.1,30.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=43),@member8,DATEADD(day,-48,@Today),68.0,28.0,23.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=44),@member8,DATEADD(day,-41,@Today),67.57,27.7,23.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=45),@member8,DATEADD(day,-34,@Today),67.14,27.4,23.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=46),@member8,DATEADD(day,-27,@Today),66.71,27.1,23.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=47),@member8,DATEADD(day,-20,@Today),66.28,26.8,23.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=49),@member9,DATEADD(day,-48,@Today),69.0,29.0,24.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=50),@member9,DATEADD(day,-41,@Today),68.57,28.7,24.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=51),@member9,DATEADD(day,-34,@Today),68.14,28.4,24.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=55),@member10,DATEADD(day,-49,@Today),70.0,30.0,25.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=56),@member10,DATEADD(day,-42,@Today),69.57,29.7,25.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=57),@member10,DATEADD(day,-35,@Today),69.14,29.4,25.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=58),@member10,DATEADD(day,-28,@Today),68.71,29.1,25.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=61),@member11,DATEADD(day,-48,@Today),71.0,31.0,26.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=62),@member11,DATEADD(day,-41,@Today),70.57,30.7,26.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=63),@member11,DATEADD(day,-34,@Today),70.14,30.4,26.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=64),@member11,DATEADD(day,-27,@Today),69.71,30.1,26.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=65),@member11,DATEADD(day,-20,@Today),69.28,29.8,26.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=67),@member12,DATEADD(day,-49,@Today),72.0,26.0,27.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=68),@member12,DATEADD(day,-42,@Today),71.57,25.7,27.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=69),@member12,DATEADD(day,-35,@Today),71.14,25.4,27.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=73),@member13,DATEADD(day,-59,@Today),73.0,27.0,28.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=74),@member13,DATEADD(day,-52,@Today),72.57,26.7,28.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=75),@member13,DATEADD(day,-45,@Today),72.14,26.4,28.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=76),@member13,DATEADD(day,-38,@Today),71.71,26.1,28.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=79),@member14,DATEADD(day,-37,@Today),74.0,28.0,29.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=80),@member14,DATEADD(day,-30,@Today),73.57,27.7,29.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=81),@member14,DATEADD(day,-23,@Today),73.14,27.4,29.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=82),@member14,DATEADD(day,-16,@Today),72.71,27.1,29.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=83),@member14,DATEADD(day,-9,@Today),72.28,26.8,29.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=85),@member15,DATEADD(day,-59,@Today),75.0,29.0,30.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=86),@member15,DATEADD(day,-52,@Today),74.57,28.7,30.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=87),@member15,DATEADD(day,-45,@Today),74.14,28.4,30.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=88),@member15,DATEADD(day,-38,@Today),73.71,28.1,30.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=89),@member15,DATEADD(day,-31,@Today),73.28,27.8,30.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=90),@member15,DATEADD(day,-24,@Today),72.85,27.5,31.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=91),@member16,DATEADD(day,-87,@Today),76.0,30.0,23.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=109),@member20,DATEADD(day,-49,@Today),62.0,28.0,27.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=110),@member20,DATEADD(day,-42,@Today),61.57,27.7,27.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=111),@member20,DATEADD(day,-35,@Today),61.14,27.4,27.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=112),@member20,DATEADD(day,-28,@Today),60.71,27.1,27.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=113),@member20,DATEADD(day,-21,@Today),60.28,26.8,27.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=115),@member21,DATEADD(day,-59,@Today),63.0,29.0,28.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=116),@member21,DATEADD(day,-52,@Today),62.57,28.7,28.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=117),@member21,DATEADD(day,-45,@Today),62.14,28.4,28.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=121),@member22,DATEADD(day,-37,@Today),64.0,30.0,29.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=122),@member22,DATEADD(day,-30,@Today),63.57,29.7,29.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=123),@member22,DATEADD(day,-23,@Today),63.14,29.4,29.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=124),@member22,DATEADD(day,-16,@Today),62.71,29.1,29.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=127),@member23,DATEADD(day,-59,@Today),65.0,31.0,30.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=128),@member23,DATEADD(day,-52,@Today),64.57,30.7,30.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=129),@member23,DATEADD(day,-45,@Today),64.14,30.4,30.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=130),@member23,DATEADD(day,-38,@Today),63.71,30.1,30.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=131),@member23,DATEADD(day,-31,@Today),63.28,29.8,30.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=132),@member23,DATEADD(day,-24,@Today),62.85,29.5,31.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=133),@member24,DATEADD(day,-87,@Today),66.0,26.0,23.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=151),@member28,DATEADD(day,-49,@Today),70.0,30.0,27.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=152),@member28,DATEADD(day,-42,@Today),69.57,29.7,27.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=153),@member28,DATEADD(day,-35,@Today),69.14,29.4,27.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=154),@member28,DATEADD(day,-28,@Today),68.71,29.1,27.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=157),@member29,DATEADD(day,-59,@Today),71.0,31.0,28.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=158),@member29,DATEADD(day,-52,@Today),70.57,30.7,28.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=159),@member29,DATEADD(day,-45,@Today),70.14,30.4,28.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=160),@member29,DATEADD(day,-38,@Today),69.71,30.1,28.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=161),@member29,DATEADD(day,-31,@Today),69.28,29.8,28.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=163),@member30,DATEADD(day,-37,@Today),72.0,26.0,29.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=164),@member30,DATEADD(day,-30,@Today),71.57,25.7,29.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=165),@member30,DATEADD(day,-23,@Today),71.14,25.4,29.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=169),@member31,DATEADD(day,-59,@Today),73.0,27.0,30.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=170),@member31,DATEADD(day,-52,@Today),72.57,26.7,30.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=171),@member31,DATEADD(day,-45,@Today),72.14,26.4,30.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=172),@member31,DATEADD(day,-38,@Today),71.71,26.1,30.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=173),@member31,DATEADD(day,-31,@Today),71.28,25.8,30.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=174),@member31,DATEADD(day,-24,@Today),70.85,25.5,31.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=175),@member32,DATEADD(day,-87,@Today),74.0,28.0,23.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=193),@member36,DATEADD(day,-49,@Today),60.0,26.0,27.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=194),@member36,DATEADD(day,-42,@Today),59.57,25.7,27.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=195),@member36,DATEADD(day,-35,@Today),59.14,25.4,27.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=199),@member37,DATEADD(day,-59,@Today),61.0,27.0,28.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=200),@member37,DATEADD(day,-52,@Today),60.57,26.7,28.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=201),@member37,DATEADD(day,-45,@Today),60.14,26.4,28.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=202),@member37,DATEADD(day,-38,@Today),59.71,26.1,28.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=205),@member38,DATEADD(day,-37,@Today),62.0,28.0,29.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=206),@member38,DATEADD(day,-30,@Today),61.57,27.7,29.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=207),@member38,DATEADD(day,-23,@Today),61.14,27.4,29.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=208),@member38,DATEADD(day,-16,@Today),60.71,27.1,29.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=209),@member38,DATEADD(day,-9,@Today),60.28,26.8,29.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=211),@member39,DATEADD(day,-59,@Today),63.0,29.0,30.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=212),@member39,DATEADD(day,-52,@Today),62.57,28.7,30.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=213),@member39,DATEADD(day,-45,@Today),62.14,28.4,30.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=214),@member39,DATEADD(day,-38,@Today),61.71,28.1,30.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=215),@member39,DATEADD(day,-31,@Today),61.28,27.8,30.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=216),@member39,DATEADD(day,-24,@Today),60.85,27.5,31.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=217),@member40,DATEADD(day,-87,@Today),64.0,30.0,23.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=235),@member44,DATEADD(day,-59,@Today),68.0,28.0,27.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=236),@member44,DATEADD(day,-52,@Today),67.57,27.7,27.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=237),@member44,DATEADD(day,-45,@Today),67.14,27.4,27.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=238),@member44,DATEADD(day,-38,@Today),66.71,27.1,27.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=239),@member44,DATEADD(day,-31,@Today),66.28,26.8,27.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=241),@member45,DATEADD(day,-37,@Today),69.0,29.0,28.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=242),@member45,DATEADD(day,-30,@Today),68.57,28.7,28.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=243),@member45,DATEADD(day,-23,@Today),68.14,28.4,28.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=247),@member46,DATEADD(day,-59,@Today),70.0,30.0,29.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=248),@member46,DATEADD(day,-52,@Today),69.57,29.7,29.2);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=249),@member46,DATEADD(day,-45,@Today),69.14,29.4,29.4);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=250),@member46,DATEADD(day,-38,@Today),68.71,29.1,29.6);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=251),@member46,DATEADD(day,-31,@Today),68.28,28.8,29.8);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=252),@member46,DATEADD(day,-24,@Today),67.85,28.5,30.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=253),@member47,DATEADD(day,-87,@Today),71.0,31.0,30.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=271),@member17,DATEADD(day,-3,@Today),77.0,31.0,24.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=272),@member15,DATEADD(day,-3,@Today),75.0,29.0,30.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=273),@member25,DATEADD(day,-3,@Today),67.0,27.0,24.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=274),@member33,DATEADD(day,-3,@Today),75.0,29.0,24.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=275),@member31,DATEADD(day,-3,@Today),73.0,27.0,30.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=276),@member41,DATEADD(day,-3,@Today),65.0,31.0,24.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=277),@member39,DATEADD(day,-3,@Today),63.0,29.0,30.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=278),@member48,DATEADD(day,-3,@Today),72.0,26.0,23.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=279),@member46,DATEADD(day,-3,@Today),70.0,30.0,29.0);
INSERT INTO dbo.inbodyrecords(attendanceid,memberid,recorddate,weight,bodyfatpct,musclemass) VALUES((SELECT attendanceid FROM @AttendanceMap WHERE casekey=310),@member2,DATEADD(day,-3,@Today),62.0,28.0,25.0);
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-12,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-11,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-10,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'DECLINED',N'OTHER',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-9,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-8,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-7,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-6,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'DECLINED',N'OTHER',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-5,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=1),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'DECLINED',N'OTHER',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-20,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=2),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'AGREED',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-12,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-11,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-10,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'DECLINED',N'OTHER',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-9,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-8,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-7,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-6,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'DECLINED',N'OTHER',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-5,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=3),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'DECLINED',N'OTHER',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-20,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-12,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-11,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-10,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'DECLINED',N'OTHER',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-9,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-8,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-7,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-6,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'DECLINED',N'OTHER',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-5,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=4),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'DECLINED',N'OTHER',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-20,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-12,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-11,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-10,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'DECLINED',N'OTHER',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-9,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-8,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-7,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-6,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'DECLINED',N'OTHER',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-5,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=5),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'DECLINED',N'OTHER',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-20,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-12,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-11,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-10,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'DECLINED',N'OTHER',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-9,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-8,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-7,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-6,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'DECLINED',N'OTHER',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-5,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=6),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'DECLINED',N'OTHER',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-20,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=7),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'AGREED',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=8),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'AGREED',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=9),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'AGREED',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=10),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'DECLINED',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=10),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'DECLINED',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=11),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'AGREED',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=12),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'DECLINED',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=12),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'DECLINED',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=13),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-5,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=13),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=13),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=14),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-5,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=14),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=14),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=16),(SELECT coachid FROM dbo.coach WHERE coachno=N'C001'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=20),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'DECLINED',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=20),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'DECLINED',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=21),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-5,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=21),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=21),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=22),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-5,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=22),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=22),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=24),(SELECT coachid FROM dbo.coach WHERE coachno=N'C002'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=28),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'DECLINED',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=28),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'DECLINED',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=29),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-5,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=29),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=29),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=30),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-5,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=30),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=30),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=32),(SELECT coachid FROM dbo.coach WHERE coachno=N'C003'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=36),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'DECLINED',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=36),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'DECLINED',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=37),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-5,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=37),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=37),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=38),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-5,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=38),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=38),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=40),(SELECT coachid FROM dbo.coach WHERE coachno=N'C004'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=44),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-5,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=44),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=44),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=45),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-5,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=45),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'CONSIDERING',N'MESSAGE',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-4,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=45),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'AGREED',N'IN_PERSON',N'確認上課安排。
後續依學員回覆追蹤。',DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.followup(membercourseid,coachid,status,contactmethod,note,createdate) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=47),(SELECT coachid FROM dbo.coach WHERE coachno=N'C005'),N'NO_RESPONSE',N'PHONE',NULL,DATEADD(minute,600,CAST(DATEADD(day,-3,@Today) AS datetime)));
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=15),(SELECT membercourseid FROM @PlanMap WHERE casekey=52),DATEADD(minute,900,CAST(DATEADD(day,-3,@Today) AS datetime)),12,7999,N'cash',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=15),(SELECT membercourseid FROM @PlanMap WHERE casekey=53),DATEADD(minute,900,CAST(DATEADD(day,-2,@Today) AS datetime)),12,7300,N'transfer',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=16),(SELECT membercourseid FROM @PlanMap WHERE casekey=54),DATEADD(minute,900,CAST(DATEADD(day,-2,@Today) AS datetime)),12,7400,N'card',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=17),(SELECT membercourseid FROM @PlanMap WHERE casekey=55),DATEADD(minute,900,CAST(DATEADD(day,-5,@Today) AS datetime)),12,7500,N'cash',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=23),(SELECT membercourseid FROM @PlanMap WHERE casekey=58),DATEADD(minute,900,CAST(DATEADD(day,-3,@Today) AS datetime)),12,7600,N'transfer',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=23),(SELECT membercourseid FROM @PlanMap WHERE casekey=59),DATEADD(minute,900,CAST(DATEADD(day,-2,@Today) AS datetime)),12,7700,N'card',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=24),(SELECT membercourseid FROM @PlanMap WHERE casekey=60),DATEADD(minute,900,CAST(DATEADD(day,-2,@Today) AS datetime)),12,7800,N'cash',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=25),(SELECT membercourseid FROM @PlanMap WHERE casekey=61),DATEADD(minute,900,CAST(DATEADD(day,-5,@Today) AS datetime)),12,7900,N'transfer',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=31),(SELECT membercourseid FROM @PlanMap WHERE casekey=63),DATEADD(minute,900,CAST(DATEADD(day,-3,@Today) AS datetime)),12,8000,N'card',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=31),(SELECT membercourseid FROM @PlanMap WHERE casekey=64),DATEADD(minute,900,CAST(DATEADD(day,-2,@Today) AS datetime)),12,8100,N'cash',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=32),(SELECT membercourseid FROM @PlanMap WHERE casekey=65),DATEADD(minute,900,CAST(DATEADD(day,-2,@Today) AS datetime)),12,8200,N'transfer',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=33),(SELECT membercourseid FROM @PlanMap WHERE casekey=66),DATEADD(minute,900,CAST(DATEADD(day,-5,@Today) AS datetime)),12,8300,N'card',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=39),(SELECT membercourseid FROM @PlanMap WHERE casekey=69),DATEADD(minute,900,CAST(DATEADD(day,-3,@Today) AS datetime)),12,8400,N'cash',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=39),(SELECT membercourseid FROM @PlanMap WHERE casekey=70),DATEADD(minute,900,CAST(DATEADD(day,-2,@Today) AS datetime)),12,8500,N'transfer',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=40),(SELECT membercourseid FROM @PlanMap WHERE casekey=71),DATEADD(minute,900,CAST(DATEADD(day,-2,@Today) AS datetime)),12,8600,N'card',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=41),(SELECT membercourseid FROM @PlanMap WHERE casekey=72),DATEADD(minute,900,CAST(DATEADD(day,-5,@Today) AS datetime)),12,8700,N'cash',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=46),(SELECT membercourseid FROM @PlanMap WHERE casekey=75),DATEADD(minute,900,CAST(DATEADD(day,-3,@Today) AS datetime)),12,8800,N'transfer',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=46),(SELECT membercourseid FROM @PlanMap WHERE casekey=76),DATEADD(minute,900,CAST(DATEADD(day,-2,@Today) AS datetime)),12,8900,N'card',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=47),(SELECT membercourseid FROM @PlanMap WHERE casekey=77),DATEADD(minute,900,CAST(DATEADD(day,-2,@Today) AS datetime)),12,9000,N'cash',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
INSERT INTO dbo.renewal(membercourseid,newmembercourseid,renewaldate,addedsessions,amount,paymentmethod,note) VALUES((SELECT membercourseid FROM @PlanMap WHERE casekey=48),(SELECT membercourseid FROM @PlanMap WHERE casekey=78),DATEADD(minute,900,CAST(DATEADD(day,-5,@Today) AS datetime)),12,9100,N'transfer',N'獨立新購課；購買日補登，登錄日另記；舊資料保留');
UPDATE dbo.member SET status=N'inactive' WHERE memberid=@member14; -- 模擬今天停用，保留先前歷史。
UPDATE dbo.member SET status=N'inactive' WHERE memberid=@member22; -- 模擬今天停用，保留先前歷史。
UPDATE dbo.member SET status=N'inactive' WHERE memberid=@member30; -- 模擬今天停用，保留先前歷史。
UPDATE dbo.member SET status=N'inactive' WHERE memberid=@member38; -- 模擬今天停用，保留先前歷史。
UPDATE dbo.member SET status=N'inactive' WHERE memberid=@member45; -- 模擬今天停用，保留先前歷史。
-- 驗收失敗則整份 rollback。
DECLARE @Expected TABLE(tablename sysname,n int);
INSERT INTO @Expected VALUES(N'useraccount',56);
INSERT INTO @Expected VALUES(N'coach',5);
INSERT INTO @Expected VALUES(N'course',5);
INSERT INTO @Expected VALUES(N'coachcourse',10);
INSERT INTO @Expected VALUES(N'member',50);
INSERT INTO @Expected VALUES(N'membercourse',85);
INSERT INTO @Expected VALUES(N'classschedule',570);
INSERT INTO @Expected VALUES(N'booking',430);
INSERT INTO @Expected VALUES(N'attendance',375);
INSERT INTO @Expected VALUES(N'inbodyrecords',157);
INSERT INTO @Expected VALUES(N'followup',110);
INSERT INTO @Expected VALUES(N'renewal',20);
IF (SELECT COUNT(*) FROM dbo.useraccount)<>56 THROW 51002,N'useraccount 筆數不符',1;
IF (SELECT COUNT(*) FROM dbo.coach)<>5 THROW 51002,N'coach 筆數不符',1;
IF (SELECT COUNT(*) FROM dbo.course)<>5 THROW 51002,N'course 筆數不符',1;
IF (SELECT COUNT(*) FROM dbo.coachcourse)<>10 THROW 51002,N'coachcourse 筆數不符',1;
IF (SELECT COUNT(*) FROM dbo.member)<>50 THROW 51002,N'member 筆數不符',1;
IF (SELECT COUNT(*) FROM dbo.membercourse)<>85 THROW 51002,N'membercourse 筆數不符',1;
IF (SELECT COUNT(*) FROM dbo.classschedule)<>570 THROW 51002,N'classschedule 筆數不符',1;
IF (SELECT COUNT(*) FROM dbo.booking)<>430 THROW 51002,N'booking 筆數不符',1;
IF (SELECT COUNT(*) FROM dbo.attendance)<>375 THROW 51002,N'attendance 筆數不符',1;
IF (SELECT COUNT(*) FROM dbo.inbodyrecords)<>157 THROW 51002,N'inbodyrecords 筆數不符',1;
IF (SELECT COUNT(*) FROM dbo.followup)<>110 THROW 51002,N'followup 筆數不符',1;
IF (SELECT COUNT(*) FROM dbo.renewal)<>20 THROW 51002,N'renewal 筆數不符',1;
IF EXISTS (SELECT 1 FROM dbo.membercourse m OUTER APPLY(SELECT COUNT(*) n FROM dbo.booking b JOIN dbo.attendance a ON a.bookingid=b.bookingid WHERE b.membercourseid=m.membercourseid AND b.bookingstatus=N'booked' AND a.attendancestatus=N'PRESENT') x WHERE m.totalsessions-x.n<>m.remainingsessions OR (m.remainingsessions=0 AND m.status<>N'usedup') OR (m.remainingsessions>0 AND m.status<>N'active')) THROW 51001,N'堂數或方案狀態錯誤',1;
IF EXISTS (SELECT 1 FROM dbo.booking b JOIN dbo.membercourse m ON m.membercourseid=b.membercourseid JOIN dbo.classschedule s ON s.scheduleid=b.scheduleid WHERE m.coachid<>s.coachid OR m.courseid<>s.courseid OR m.purchasedate>s.classdate OR b.bookingtime<CAST(m.purchasedate AS datetime) OR b.bookingtime>DATEADD(second,DATEDIFF(second,CAST('00:00' AS time),s.starttime),CAST(s.classdate AS datetime)) OR b.bookingtime>@Now OR b.updatetime>@Now) THROW 51001,N'預約配對或日期異常',1;
IF EXISTS (SELECT 1 FROM dbo.booking WHERE bookingstatus NOT IN(N'booked',N'cancelled')) THROW 51001,N'預約狀態錯誤',1;
IF EXISTS (SELECT 1 FROM dbo.booking WHERE bookingstatus=N'booked' GROUP BY scheduleid HAVING COUNT(*)>1) THROW 51001,N'同時段重複預約',1;
IF EXISTS (SELECT 1 FROM dbo.attendance a JOIN dbo.booking b ON b.bookingid=a.bookingid JOIN dbo.classschedule s ON s.scheduleid=b.scheduleid WHERE a.attendancestatus NOT IN(N'PRESENT',N'PENDING',N'LEAVE',N'ABSENT') OR (b.bookingstatus=N'cancelled' AND a.attendancestatus=N'PRESENT') OR (a.attendancestatus IN(N'PRESENT',N'LEAVE',N'ABSENT') AND DATEADD(second,DATEDIFF(second,CAST('00:00' AS time),s.starttime),CAST(s.classdate AS datetime))>@Now) OR a.updatetime>@Now OR a.checkintime>@Now) THROW 51001,N'出席狀態或未來完成時間錯誤',1;
IF EXISTS (SELECT 1 FROM dbo.inbodyrecords i JOIN dbo.attendance a ON a.attendanceid=i.attendanceid JOIN dbo.booking b ON b.bookingid=a.bookingid JOIN dbo.membercourse m ON m.membercourseid=b.membercourseid JOIN dbo.classschedule s ON s.scheduleid=b.scheduleid WHERE i.memberid<>m.memberid OR a.attendancestatus<>N'PRESENT' OR b.bookingstatus<>N'booked' OR i.recorddate IS NULL OR i.recorddate<>s.classdate OR i.recorddate>@Today OR i.weight IS NULL OR i.bodyfatpct IS NULL OR i.musclemass IS NULL OR i.weight<=0 OR i.bodyfatpct<=0 OR i.musclemass<=0) THROW 51001,N'InBody 歸屬或量測錯誤',1;
IF EXISTS (SELECT 1 FROM dbo.followup f JOIN dbo.membercourse m ON m.membercourseid=f.membercourseid WHERE f.coachid<>m.coachid OR f.createdate IS NULL OR f.createdate>@Now OR DATEPART(second,f.createdate)<>0 OR f.status NOT IN(N'NO_RESPONSE',N'CONSIDERING',N'AGREED',N'DECLINED') OR f.contactmethod NOT IN(N'PHONE',N'MESSAGE',N'IN_PERSON',N'OTHER') OR DATALENGTH(f.note)>1000) THROW 51001,N'跟進格式錯誤',1;
IF EXISTS (SELECT 1 FROM dbo.renewal r JOIN dbo.membercourse o ON o.membercourseid=r.membercourseid JOIN dbo.membercourse n ON n.membercourseid=r.newmembercourseid WHERE o.memberid<>n.memberid OR o.coachid<>n.coachid OR r.membercourseid=r.newmembercourseid OR r.addedsessions<>n.totalsessions OR n.purchasedate<o.purchasedate OR n.purchasedate>CAST(r.renewaldate AS date) OR r.renewaldate>@Now OR r.paymentmethod NOT IN(N'cash',N'transfer',N'card')) THROW 51001,N'續約關聯錯誤',1;
IF EXISTS (SELECT 1 FROM dbo.membercourse x LEFT JOIN dbo.coachcourse cc ON cc.coachid=x.coachid AND cc.courseid=x.courseid WHERE cc.coachid IS NULL) THROW 51001,N'授課配對不存在',1;
IF EXISTS (SELECT 1 FROM dbo.classschedule x LEFT JOIN dbo.coachcourse cc ON cc.coachid=x.coachid AND cc.courseid=x.courseid WHERE cc.coachid IS NULL) THROW 51001,N'授課配對不存在',1;
IF EXISTS (SELECT 1 FROM dbo.booking b JOIN dbo.classschedule s ON s.scheduleid=b.scheduleid JOIN dbo.membercourse m ON m.membercourseid=b.membercourseid JOIN dbo.booking b2 ON b2.bookingid>b.bookingid JOIN dbo.classschedule s2 ON s2.scheduleid=b2.scheduleid JOIN dbo.membercourse m2 ON m2.membercourseid=b2.membercourseid WHERE b.bookingstatus=N'booked' AND b2.bookingstatus=N'booked' AND s.classdate=s2.classdate AND s.starttime<s2.endtime AND s2.starttime<s.endtime AND (s.coachid=s2.coachid OR m.memberid=m2.memberid)) THROW 51001,N'有效預約時段衝突',1;
IF EXISTS (SELECT 1 FROM dbo.classschedule s JOIN dbo.classschedule s2 ON s2.scheduleid>s.scheduleid WHERE s.classdate=s2.classdate AND s.starttime<s2.endtime AND s2.starttime<s.endtime AND (s.coachid=s2.coachid OR s.classroom=s2.classroom)) THROW 51001,N'教練或教室排課衝突',1;
IF EXISTS (SELECT 1 FROM dbo.coach c LEFT JOIN dbo.membercourse m ON m.coachid=c.coachid GROUP BY c.coachid HAVING COUNT(DISTINCT m.memberid)<10 OR COUNT(m.membercourseid)<=10) THROW 51001,N'教練資料量不足',1;
DECLARE @Cases TABLE(membercourseid int PRIMARY KEY,coachid int,memberid int,courseid int,purchaseDate date,remaining int,baseline date,lastPresent date,hasRenewed bit,highPriority bit,upcoming bit,longAbsent bit,completed bit);
INSERT INTO @Cases
SELECT m.membercourseid,m.coachid,m.memberid,m.courseid,m.purchasedate,m.remainingsessions,COALESCE(x.lastPresent,x.firstPurchase),x.lastPresent,r.hasRenewed,
CASE WHEN m.remainingsessions BETWEEN 1 AND 5 AND r.hasRenewed=0 THEN 1 ELSE 0 END,
CASE WHEN m.remainingsessions BETWEEN 6 AND 10 AND r.hasRenewed=0 THEN 1 ELSE 0 END,
CASE WHEN m.remainingsessions>0 AND DATEDIFF(day,COALESCE(x.lastPresent,x.firstPurchase),@Today)>=14 THEN 1 ELSE 0 END,
CASE WHEN m.remainingsessions=0 AND r.hasRenewed=0 THEN 1 ELSE 0 END
FROM dbo.membercourse m
OUTER APPLY(SELECT MAX(CASE WHEN b.bookingstatus=N'booked' AND a.attendancestatus=N'PRESENT' AND s.classdate<=@Today THEN s.classdate END) lastPresent,
 MIN(CASE WHEN m2.purchasedate<=@Today THEN m2.purchasedate END) firstPurchase
 FROM dbo.membercourse m2 LEFT JOIN dbo.booking b ON b.membercourseid=m2.membercourseid LEFT JOIN dbo.attendance a ON a.bookingid=b.bookingid LEFT JOIN dbo.classschedule s ON s.scheduleid=b.scheduleid
 WHERE m2.memberid=m.memberid AND m2.coachid=m.coachid AND m2.courseid=m.courseid) x
CROSS APPLY(SELECT CAST(CASE WHEN EXISTS(SELECT 1 FROM dbo.renewal rr WHERE rr.membercourseid=m.membercourseid) THEN 1 ELSE 0 END AS bit) hasRenewed) r;
DECLARE @ExpectedCases TABLE(casekey int PRIMARY KEY,baselineOffset int,highPriority bit,upcoming bit,longAbsent bit,completed bit);
INSERT INTO @ExpectedCases VALUES(1,DATEDIFF(day,@Today,@ShowDate),1,0,0,0);
INSERT INTO @ExpectedCases VALUES(2,-13,1,0,0,0);
INSERT INTO @ExpectedCases VALUES(3,DATEDIFF(day,@Today,@ShowDate),1,0,0,0);
INSERT INTO @ExpectedCases VALUES(4,DATEDIFF(day,@Today,@ShowDate),1,0,0,0);
INSERT INTO @ExpectedCases VALUES(5,DATEDIFF(day,@Today,@ShowDate),1,0,0,0);
INSERT INTO @ExpectedCases VALUES(6,DATEDIFF(day,@Today,@ShowDate),1,0,0,0);
INSERT INTO @ExpectedCases VALUES(7,-13,1,0,0,0);
INSERT INTO @ExpectedCases VALUES(8,-13,1,0,0,0);
INSERT INTO @ExpectedCases VALUES(9,-13,1,0,0,0);
INSERT INTO @ExpectedCases VALUES(10,-14,0,1,1,0);
INSERT INTO @ExpectedCases VALUES(11,-13,1,0,0,0);
INSERT INTO @ExpectedCases VALUES(12,-14,0,1,1,0);
INSERT INTO @ExpectedCases VALUES(13,-24,0,1,1,0);
INSERT INTO @ExpectedCases VALUES(14,-2,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(15,-24,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(16,-10,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(17,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(18,-30,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(19,-5,0,1,0,0);
INSERT INTO @ExpectedCases VALUES(20,-14,0,1,1,0);
INSERT INTO @ExpectedCases VALUES(21,-24,0,1,1,0);
INSERT INTO @ExpectedCases VALUES(22,-2,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(23,-24,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(24,-10,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(25,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(26,-30,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(27,-5,0,1,0,0);
INSERT INTO @ExpectedCases VALUES(28,-14,0,1,1,0);
INSERT INTO @ExpectedCases VALUES(29,-24,0,1,1,0);
INSERT INTO @ExpectedCases VALUES(30,-2,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(31,-24,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(32,-10,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(33,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(34,-30,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(35,-5,0,1,0,0);
INSERT INTO @ExpectedCases VALUES(36,-14,0,1,1,0);
INSERT INTO @ExpectedCases VALUES(37,-24,0,1,1,0);
INSERT INTO @ExpectedCases VALUES(38,-2,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(39,-24,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(40,-10,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(41,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(42,-30,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(43,-5,0,1,0,0);
INSERT INTO @ExpectedCases VALUES(44,-24,0,1,1,0);
INSERT INTO @ExpectedCases VALUES(45,-2,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(46,-24,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(47,-10,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(48,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(49,-30,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(50,-5,0,1,0,0);
INSERT INTO @ExpectedCases VALUES(51,-30,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(52,-24,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(53,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(54,-10,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(55,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(56,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(57,-30,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(58,-24,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(59,-24,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(60,-10,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(61,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(62,-30,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(63,-24,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(64,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(65,-10,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(66,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(67,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(68,-30,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(69,-24,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(70,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(71,-10,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(72,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(73,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(74,-30,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(75,-24,0,0,1,0);
INSERT INTO @ExpectedCases VALUES(76,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(77,-10,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(78,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(79,-3,0,0,0,0);
INSERT INTO @ExpectedCases VALUES(80,-10,0,0,0,1);
INSERT INTO @ExpectedCases VALUES(81,-10,0,0,0,1);
INSERT INTO @ExpectedCases VALUES(82,-10,0,0,0,1);
INSERT INTO @ExpectedCases VALUES(83,-10,0,0,0,1);
INSERT INTO @ExpectedCases VALUES(84,-10,0,0,0,1);
INSERT INTO @ExpectedCases VALUES(85,-3,0,0,0,0);
IF EXISTS (SELECT 1 FROM @ExpectedCases e JOIN @PlanMap pm ON pm.casekey=e.casekey JOIN @Cases c ON c.membercourseid=pm.membercourseid WHERE DATEDIFF(day,@Today,c.baseline)<>e.baselineOffset OR c.highPriority<>e.highPriority OR c.upcoming<>e.upcoming OR c.longAbsent<>e.longAbsent OR c.completed<>e.completed) THROW 51001,N'分類邊界或同組基準錯誤',1;
COMMIT TRANSACTION;
SELECT @Now AS seedAsOfDateTime,@Today AS today,@ShowDate AS attendanceShowDate,N'展示日若為今天，另有19/20點待確認，合計8筆；昨天為6筆' AS note;
SELECT N'useraccount' tablename,56 expectedCount,COUNT(*) actualCount FROM dbo.useraccount
UNION ALL
SELECT N'coach' tablename,5 expectedCount,COUNT(*) actualCount FROM dbo.coach
UNION ALL
SELECT N'course' tablename,5 expectedCount,COUNT(*) actualCount FROM dbo.course
UNION ALL
SELECT N'coachcourse' tablename,10 expectedCount,COUNT(*) actualCount FROM dbo.coachcourse
UNION ALL
SELECT N'member' tablename,50 expectedCount,COUNT(*) actualCount FROM dbo.member
UNION ALL
SELECT N'membercourse' tablename,85 expectedCount,COUNT(*) actualCount FROM dbo.membercourse
UNION ALL
SELECT N'classschedule' tablename,570 expectedCount,COUNT(*) actualCount FROM dbo.classschedule
UNION ALL
SELECT N'booking' tablename,430 expectedCount,COUNT(*) actualCount FROM dbo.booking
UNION ALL
SELECT N'attendance' tablename,375 expectedCount,COUNT(*) actualCount FROM dbo.attendance
UNION ALL
SELECT N'inbodyrecords' tablename,157 expectedCount,COUNT(*) actualCount FROM dbo.inbodyrecords
UNION ALL
SELECT N'followup' tablename,110 expectedCount,COUNT(*) actualCount FROM dbo.followup
UNION ALL
SELECT N'renewal' tablename,20 expectedCount,COUNT(*) actualCount FROM dbo.renewal;
SELECT c.name,COUNT(*) authorizedPlanCount,
SUM(CAST(x.highPriority AS int)) highPriority,SUM(CAST(x.upcoming AS int)) upcoming,SUM(CAST(x.longAbsent AS int)) longAbsent,SUM(CAST(x.completed AS int)) completed,
SUM(CASE WHEN x.highPriority=1 OR x.upcoming=1 OR x.longAbsent=1 OR x.completed=1 THEN 1 ELSE 0 END) trackingPlanCount
FROM @Cases x JOIN dbo.coach c ON c.coachid=x.coachid GROUP BY c.name;
SELECT c.name,COUNT(*) total,
SUM(CASE WHEN b.bookingstatus=N'cancelled' THEN 1 ELSE 0 END) cancelled,
SUM(CASE WHEN b.bookingstatus=N'booked' AND a.attendancestatus=N'PRESENT' THEN 1 ELSE 0 END) present,
SUM(CASE WHEN b.bookingstatus=N'booked' AND (a.attendanceid IS NULL OR a.attendancestatus=N'PENDING') THEN 1 ELSE 0 END) pending,
SUM(CASE WHEN b.bookingstatus=N'booked' AND a.attendancestatus=N'LEAVE' THEN 1 ELSE 0 END) leaveCount,
SUM(CASE WHEN b.bookingstatus=N'booked' AND a.attendancestatus=N'ABSENT' THEN 1 ELSE 0 END) absent
FROM dbo.booking b JOIN dbo.classschedule s ON s.scheduleid=b.scheduleid JOIN dbo.coach c ON c.coachid=s.coachid LEFT JOIN dbo.attendance a ON a.bookingid=b.bookingid WHERE s.classdate=@ShowDate GROUP BY c.name;
SELECT u.accountid,u.username,u.role,u.status,c.coachid,m.memberid,m.name,m.status memberStatus FROM dbo.useraccount u LEFT JOIN dbo.coach c ON c.accountid=u.accountid LEFT JOIN dbo.member m ON m.accountid=u.accountid ORDER BY u.accountid;
SELECT pm.casekey,x.*,m.name,c.name coach,co.coursename,
(SELECT COUNT(*) FROM dbo.followup f WHERE f.membercourseid=x.membercourseid) followupCount,
(SELECT COUNT(*) FROM dbo.inbodyrecords i JOIN dbo.attendance a ON a.attendanceid=i.attendanceid JOIN dbo.booking b ON b.bookingid=a.bookingid WHERE b.membercourseid=x.membercourseid) inbodyCount
FROM @Cases x JOIN @PlanMap pm ON pm.membercourseid=x.membercourseid JOIN dbo.member m ON m.memberid=x.memberid JOIN dbo.coach c ON c.coachid=x.coachid JOIN dbo.course co ON co.courseid=x.courseid ORDER BY x.coachid,x.purchaseDate DESC,x.membercourseid DESC;
SELECT sm.casekey,s.*,b.bookingid,b.membercourseid,b.bookingstatus,a.attendanceid,a.attendancestatus FROM @ScheduleMap sm JOIN dbo.classschedule s ON s.scheduleid=sm.scheduleid LEFT JOIN dbo.booking b ON b.scheduleid=s.scheduleid LEFT JOIN dbo.attendance a ON a.bookingid=b.bookingid ORDER BY s.classdate,s.starttime,s.coachid;
SELECT * FROM dbo.renewal ORDER BY renewaldate DESC,renewalid DESC;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO




----------------------------

SELECT * FROM dbo.useraccount;
SELECT * FROM dbo.coach;
SELECT * FROM dbo.course;
SELECT * FROM dbo.coachcourse;
SELECT * FROM dbo.member;
SELECT * FROM dbo.membercourse;
SELECT * FROM dbo.classschedule;
SELECT * FROM dbo.booking;
SELECT * FROM dbo.attendance;
SELECT * FROM dbo.inbodyrecords;
SELECT * FROM dbo.followup;
SELECT * FROM dbo.renewal;