USE gym;
GO

/* =========================================================
清除整套測試資料
注意：依照 FK 關聯，由子表往父表刪除

DELETE FROM dbo.renewal;
DELETE FROM dbo.followup;
DELETE FROM dbo.inbodyrecords;
DELETE FROM dbo.attendance;
DELETE FROM dbo.booking;
DELETE FROM dbo.classschedule;
DELETE FROM dbo.coachcourse;
DELETE FROM dbo.membercourse;
DELETE FROM dbo.member;
DELETE FROM dbo.coach;
DELETE FROM dbo.course;
DELETE FROM dbo.useraccount;
GO

IDENTITY 全部重新從 1 開始
RESEED = 0，下一筆 INSERT 就會得到 ID = 1

DBCC CHECKIDENT ('dbo.renewal', RESEED, 0);
DBCC CHECKIDENT ('dbo.followup', RESEED, 0);
DBCC CHECKIDENT ('dbo.inbodyrecords', RESEED, 0);
DBCC CHECKIDENT ('dbo.attendance', RESEED, 0);
DBCC CHECKIDENT ('dbo.booking', RESEED, 0);
DBCC CHECKIDENT ('dbo.classschedule', RESEED, 0);
DBCC CHECKIDENT ('dbo.membercourse', RESEED, 0);
DBCC CHECKIDENT ('dbo.member', RESEED, 0);
DBCC CHECKIDENT ('dbo.coach', RESEED, 0);
DBCC CHECKIDENT ('dbo.course', RESEED, 0);
DBCC CHECKIDENT ('dbo.useraccount', RESEED, 0);
GO

========================================================= */


/* =========================================================
   建立教練帳號
   ========================================================= */

INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'coach001', N'123456', N'COACH', N'active');

DECLARE @coachAccountId INT = SCOPE_IDENTITY();


INSERT INTO dbo.coach
(accountid, coachno, name, gender, phone, email, specialty, status)
VALUES
(
    @coachAccountId,
    N'C001',
    N'陳教練',
    N'男',
    N'0912345678',
    N'coach001@gym.com',
    N'重量訓練、核心訓練',
    N'active'
);

DECLARE @coachId INT = SCOPE_IDENTITY();


/* =========================================================
   建立課程
   ========================================================= */

INSERT INTO dbo.course
(coursename, coursetype, description, durationmin, price, status)
VALUES
(
    N'私人教練一對一',
    N'PERSONAL',
    N'一對一私人教練課程',
    60,
    1500,
    N'active'
);

DECLARE @courseId INT = SCOPE_IDENTITY();


INSERT INTO dbo.coachcourse
(coachid, courseid)
VALUES
(@coachId, @courseId);


/* =========================================================
   建立六位會員
   ========================================================= */

-------------------------
-- 會員 1：王小美
-------------------------

INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member001', N'123456', N'MEMBER', N'active');

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
    N'/images/members/member01.jpg'
);

DECLARE @member1 INT = SCOPE_IDENTITY();


-------------------------
-- 會員 2：陳志豪
-------------------------

INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member002', N'123456', N'MEMBER', N'active');

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
    N'/images/members/member02.jpg'
);

DECLARE @member2 INT = SCOPE_IDENTITY();


-------------------------
-- 會員 3：林怡君
-------------------------

INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member003', N'123456', N'MEMBER', N'active');

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
    N'/images/members/member03.jpg'
);

DECLARE @member3 INT = SCOPE_IDENTITY();


-------------------------
-- 會員 4：張家豪
-------------------------

INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member004', N'123456', N'MEMBER', N'active');

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
    N'/images/members/member04.jpg'
);

DECLARE @member4 INT = SCOPE_IDENTITY();


-------------------------
-- 會員 5：李佳穎
-------------------------

INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member005', N'123456', N'MEMBER', N'active');

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
    N'/images/members/member05.jpg'
);

DECLARE @member5 INT = SCOPE_IDENTITY();


-------------------------
-- 會員 6：黃雅婷
-------------------------

INSERT INTO dbo.useraccount
(username, password, role, status)
VALUES
(N'member006', N'123456', N'MEMBER', N'active');

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
    N'/images/members/member06.jpg'
);

DECLARE @member6 INT = SCOPE_IDENTITY();


/* =========================================================
   建立會員購課資料
   ========================================================= */

-- 王小美：20堂，剩2堂 → 極低堂數
INSERT INTO dbo.membercourse
(memberid, courseid, purchasedate, totalsessions, remainingsessions, status)
VALUES
(@member1, @courseId, '2026-05-01', 20, 2, N'active');

DECLARE @mc1 INT = SCOPE_IDENTITY();


-- 陳志豪：24堂，剩5堂 → 續約提醒
INSERT INTO dbo.membercourse
(memberid, courseid, purchasedate, totalsessions, remainingsessions, status)
VALUES
(@member2, @courseId, '2026-04-15', 24, 5, N'active');

DECLARE @mc2 INT = SCOPE_IDENTITY();


-- 林怡君：20堂，剩12堂，但久未出席
INSERT INTO dbo.membercourse
(memberid, courseid, purchasedate, totalsessions, remainingsessions, status)
VALUES
(@member3, @courseId, '2026-06-01', 20, 12, N'active');

DECLARE @mc3 INT = SCOPE_IDENTITY();


-- 張家豪：課程已用完
INSERT INTO dbo.membercourse
(memberid, courseid, purchasedate, totalsessions, remainingsessions, status)
VALUES
(@member4, @courseId, '2026-02-01', 20, 0, N'active');

DECLARE @mc4 INT = SCOPE_IDENTITY();


-- 李佳穎：正常會員
INSERT INTO dbo.membercourse
(memberid, courseid, purchasedate, totalsessions, remainingsessions, status)
VALUES
(@member5, @courseId, '2026-07-01', 30, 15, N'active');

DECLARE @mc5 INT = SCOPE_IDENTITY();


-- 黃雅婷：剩2堂＋久未出席
INSERT INTO dbo.membercourse
(memberid, courseid, purchasedate, totalsessions, remainingsessions, status)
VALUES
(@member6, @courseId, '2026-03-01', 16, 2, N'active');

DECLARE @mc6 INT = SCOPE_IDENTITY();


/* =========================================================
   ClassSchedule
   按實際上課日期，由舊 → 新
   ========================================================= */

-- 1：陳志豪 06/01
INSERT INTO dbo.classschedule
(coachid, courseid, classdate, starttime, endtime, classroom, status)
VALUES
(@coachId, @courseId, '2026-06-01', '10:00', '11:00', N'A教室', N'closed');

DECLARE @s1 INT = SCOPE_IDENTITY();


-- 2：王小美 07/01
INSERT INTO dbo.classschedule
(coachid, courseid, classdate, starttime, endtime, classroom, status)
VALUES
(@coachId, @courseId, '2026-07-01', '09:00', '10:00', N'A教室', N'closed');

DECLARE @s2 INT = SCOPE_IDENTITY();


-- 3：林怡君 07/10
INSERT INTO dbo.classschedule
(coachid, courseid, classdate, starttime, endtime, classroom, status)
VALUES
(@coachId, @courseId, '2026-07-10', '14:00', '15:00', N'B教室', N'closed');

DECLARE @s3 INT = SCOPE_IDENTITY();


-- 4：黃雅婷 09/01
INSERT INTO dbo.classschedule
(coachid, courseid, classdate, starttime, endtime, classroom, status)
VALUES
(@coachId, @courseId, '2026-09-01', '18:00', '19:00', N'B教室', N'closed');

DECLARE @s4 INT = SCOPE_IDENTITY();


-- 5：林怡君 09/05
INSERT INTO dbo.classschedule
(coachid, courseid, classdate, starttime, endtime, classroom, status)
VALUES
(@coachId, @courseId, '2026-09-05', '10:00', '11:00', N'A教室', N'closed');

DECLARE @s5 INT = SCOPE_IDENTITY();


-- 6：王小美 09/24
INSERT INTO dbo.classschedule
(coachid, courseid, classdate, starttime, endtime, classroom, status)
VALUES
(@coachId, @courseId, '2026-09-24', '09:00', '10:00', N'A教室', N'closed');

DECLARE @s6 INT = SCOPE_IDENTITY();


-- 7：李佳穎 09/25
INSERT INTO dbo.classschedule
(coachid, courseid, classdate, starttime, endtime, classroom, status)
VALUES
(@coachId, @courseId, '2026-09-25', '14:00', '15:00', N'A教室', N'closed');

DECLARE @s7 INT = SCOPE_IDENTITY();


-- 8：王小美 09/27
INSERT INTO dbo.classschedule
(coachid, courseid, classdate, starttime, endtime, classroom, status)
VALUES
(@coachId, @courseId, '2026-09-27', '09:00', '10:00', N'A教室', N'open');

DECLARE @s8 INT = SCOPE_IDENTITY();


-- 9：陳志豪 09/27
INSERT INTO dbo.classschedule
(coachid, courseid, classdate, starttime, endtime, classroom, status)
VALUES
(@coachId, @courseId, '2026-09-27', '10:30', '11:30', N'A教室', N'open');

DECLARE @s9 INT = SCOPE_IDENTITY();


-- 10：林怡君 09/27（後續取消）
INSERT INTO dbo.classschedule
(coachid, courseid, classdate, starttime, endtime, classroom, status)
VALUES
(@coachId, @courseId, '2026-09-27', '13:00', '14:00', N'B教室', N'open');

DECLARE @s10 INT = SCOPE_IDENTITY();


-- 11：李佳穎 09/27
INSERT INTO dbo.classschedule
(coachid, courseid, classdate, starttime, endtime, classroom, status)
VALUES
(@coachId, @courseId, '2026-09-27', '15:00', '16:00', N'A教室', N'open');

DECLARE @s11 INT = SCOPE_IDENTITY();


/* =========================================================
   Booking
   按 Booking 建立時間由舊 → 新
   ========================================================= */

-- Booking 1：陳志豪 06/01
INSERT INTO dbo.booking
(membercourseid, scheduleid, bookingtime, bookingstatus, note, updatetime)
VALUES
(@mc2, @s1, '2026-05-28 10:00', N'BOOKED', N'歷史預約', '2026-06-01 11:00');

DECLARE @b1 INT = SCOPE_IDENTITY();


-- Booking 2：王小美 07/01
INSERT INTO dbo.booking
(membercourseid, scheduleid, bookingtime, bookingstatus, note, updatetime)
VALUES
(@mc1, @s2, '2026-06-28 10:00', N'BOOKED', N'歷史預約', '2026-07-01 10:00');

DECLARE @b2 INT = SCOPE_IDENTITY();


-- Booking 3：林怡君 07/10
INSERT INTO dbo.booking
(membercourseid, scheduleid, bookingtime, bookingstatus, note, updatetime)
VALUES
(@mc3, @s3, '2026-07-05 14:00', N'BOOKED', N'歷史預約', '2026-07-10 15:00');

DECLARE @b3 INT = SCOPE_IDENTITY();


-- Booking 4：黃雅婷 09/01
INSERT INTO dbo.booking
(membercourseid, scheduleid, bookingtime, bookingstatus, note, updatetime)
VALUES
(@mc6, @s4, '2026-08-25 10:00', N'BOOKED', N'歷史預約', '2026-09-01 19:00');

DECLARE @b4 INT = SCOPE_IDENTITY();


-- Booking 5：林怡君 09/05
INSERT INTO dbo.booking
(membercourseid, scheduleid, bookingtime, bookingstatus, note, updatetime)
VALUES
(@mc3, @s5, '2026-09-01 10:00', N'BOOKED', N'歷史預約', '2026-09-05 11:00');

DECLARE @b5 INT = SCOPE_IDENTITY();


-- Booking 6：王小美 09/24
INSERT INTO dbo.booking
(membercourseid, scheduleid, bookingtime, bookingstatus, note, updatetime)
VALUES
(@mc1, @s6, '2026-09-20 09:00', N'BOOKED', N'歷史預約', '2026-09-24 10:00');

DECLARE @b6 INT = SCOPE_IDENTITY();


-- Booking 7：王小美 09/27
INSERT INTO dbo.booking
(membercourseid, scheduleid, bookingtime, bookingstatus, note, updatetime)
VALUES
(@mc1, @s8, '2026-09-20 10:00', N'BOOKED', N'正常預約', '2026-09-20 10:00');

DECLARE @b7 INT = SCOPE_IDENTITY();


-- Booking 8：李佳穎 09/25
INSERT INTO dbo.booking
(membercourseid, scheduleid, bookingtime, bookingstatus, note, updatetime)
VALUES
(@mc5, @s7, '2026-09-20 14:00', N'BOOKED', N'歷史預約', '2026-09-25 15:00');

DECLARE @b8 INT = SCOPE_IDENTITY();


-- Booking 9：陳志豪 09/27
INSERT INTO dbo.booking
(membercourseid, scheduleid, bookingtime, bookingstatus, note, updatetime)
VALUES
(@mc2, @s9, '2026-09-21 11:00', N'BOOKED', N'正常預約', '2026-09-21 11:00');

DECLARE @b9 INT = SCOPE_IDENTITY();


-- Booking 10：林怡君 09/27，取消
INSERT INTO dbo.booking
(membercourseid, scheduleid, bookingtime, bookingstatus, note, updatetime)
VALUES
(@mc3, @s10, '2026-09-21 12:00', N'CANCELLED', N'會員臨時取消', '2026-09-26 18:00');

DECLARE @b10 INT = SCOPE_IDENTITY();


-- Booking 11：李佳穎 09/27
INSERT INTO dbo.booking
(membercourseid, scheduleid, bookingtime, bookingstatus, note, updatetime)
VALUES
(@mc5, @s11, '2026-09-22 15:00', N'BOOKED', N'正常預約', '2026-09-22 15:00');

DECLARE @b11 INT = SCOPE_IDENTITY();


/* =========================================================
   Attendance
   依照 Booking 順序建立

   Booking 10 為 CANCELLED
   因此不建立 Attendance
   ========================================================= */

-- Attendance 1 → Booking 1
INSERT INTO dbo.attendance
(bookingid, checkintime, attendancestatus, workoutfocus, note, updatetime)
VALUES
(
    @b1,
    '2026-06-01 10:55',
    N'PRESENT',
    N'重量訓練',
    N'歷史訓練紀錄',
    '2026-06-01 10:55'
);

DECLARE @a1 INT = SCOPE_IDENTITY();


-- Attendance 2 → Booking 2
INSERT INTO dbo.attendance
(bookingid, checkintime, attendancestatus, workoutfocus, note, updatetime)
VALUES
(
    @b2,
    '2026-07-01 09:55',
    N'PRESENT',
    N'重量訓練',
    N'歷史訓練紀錄',
    '2026-07-01 09:55'
);

DECLARE @a2 INT = SCOPE_IDENTITY();


-- Attendance 3 → Booking 3
INSERT INTO dbo.attendance
(bookingid, checkintime, attendancestatus, workoutfocus, note, updatetime)
VALUES
(
    @b3,
    '2026-07-10 14:55',
    N'PRESENT',
    N'核心訓練',
    N'歷史訓練紀錄',
    '2026-07-10 14:55'
);

DECLARE @a3 INT = SCOPE_IDENTITY();


-- Attendance 4 → Booking 4
INSERT INTO dbo.attendance
(bookingid, checkintime, attendancestatus, workoutfocus, note, updatetime)
VALUES
(
    @b4,
    '2026-09-01 18:55',
    N'PRESENT',
    N'TRX',
    N'TRX 全身訓練',
    '2026-09-01 18:55'
);

DECLARE @a4 INT = SCOPE_IDENTITY();


-- Attendance 5 → Booking 5
INSERT INTO dbo.attendance
(bookingid, checkintime, attendancestatus, workoutfocus, note, updatetime)
VALUES
(
    @b5,
    '2026-09-05 10:58',
    N'PRESENT',
    N'核心訓練',
    N'核心穩定訓練',
    '2026-09-05 10:58'
);

DECLARE @a5 INT = SCOPE_IDENTITY();


-- Attendance 6 → Booking 6
INSERT INTO dbo.attendance
(bookingid, checkintime, attendancestatus, workoutfocus, note, updatetime)
VALUES
(
    @b6,
    '2026-09-24 09:55',
    N'PRESENT',
    N'重量訓練',
    N'下肢訓練',
    '2026-09-24 09:55'
);

DECLARE @a6 INT = SCOPE_IDENTITY();


-- Attendance 7 → Booking 7
-- 今日待確認
INSERT INTO dbo.attendance
(bookingid, checkintime, attendancestatus, workoutfocus, note, updatetime)
VALUES
(
    @b7,
    NULL,
    N'PENDING',
    NULL,
    NULL,
    NULL
);

DECLARE @a7 INT = SCOPE_IDENTITY();


-- Attendance 8 → Booking 8
INSERT INTO dbo.attendance
(bookingid, checkintime, attendancestatus, workoutfocus, note, updatetime)
VALUES
(
    @b8,
    '2026-09-25 14:58',
    N'PRESENT',
    N'重量訓練',
    N'上肢推拉訓練',
    '2026-09-25 14:58'
);

DECLARE @a8 INT = SCOPE_IDENTITY();


-- Attendance 9 → Booking 9
INSERT INTO dbo.attendance
(bookingid, checkintime, attendancestatus, workoutfocus, note, updatetime)
VALUES
(
    @b9,
    '2026-09-27 11:25',
    N'PRESENT',
    N'重量訓練',
    N'深蹲與硬舉訓練，整體狀況良好',
    '2026-09-27 11:25'
);

DECLARE @a9 INT = SCOPE_IDENTITY();


/*
   Booking 10 = CANCELLED
   不建立 Attendance
*/


-- Attendance 10 → Booking 11
-- 李佳穎請假
INSERT INTO dbo.attendance
(bookingid, checkintime, attendancestatus, workoutfocus, note, updatetime)
VALUES
(
    @b11,
    NULL,
    N'LEAVE',
    NULL,
    N'會員身體不適請假',
    '2026-09-27 14:30'
);

DECLARE @a10 INT = SCOPE_IDENTITY();


/* =========================================================
   InBody
   只有 PRESENT Attendance 才有 InBody
   ========================================================= */

-- InBody 1：陳志豪 06/01
INSERT INTO dbo.inbodyrecords
(memberid, recorddate, weight, bodyfatpct, musclemass, attendanceid)
VALUES
(
    @member2,
    '2026-06-01',
    82.30,
    24.5,
    32.0,
    @a1
);


-- InBody 2：王小美 07/01
INSERT INTO dbo.inbodyrecords
(memberid, recorddate, weight, bodyfatpct, musclemass, attendanceid)
VALUES
(
    @member1,
    '2026-07-01',
    62.50,
    31.5,
    21.8,
    @a2
);


-- InBody 3：林怡君 07/10
INSERT INTO dbo.inbodyrecords
(memberid, recorddate, weight, bodyfatpct, musclemass, attendanceid)
VALUES
(
    @member3,
    '2026-07-10',
    57.20,
    29.2,
    20.1,
    @a3
);


-- InBody 4：林怡君 09/05
INSERT INTO dbo.inbodyrecords
(memberid, recorddate, weight, bodyfatpct, musclemass, attendanceid)
VALUES
(
    @member3,
    '2026-09-05',
    55.80,
    27.6,
    21.0,
    @a5
);


-- InBody 5：王小美 09/24
INSERT INTO dbo.inbodyrecords
(memberid, recorddate, weight, bodyfatpct, musclemass, attendanceid)
VALUES
(
    @member1,
    '2026-09-24',
    59.80,
    28.6,
    23.2,
    @a6
);


-- InBody 6：陳志豪 09/27
INSERT INTO dbo.inbodyrecords
(memberid, recorddate, weight, bodyfatpct, musclemass, attendanceid)
VALUES
(
    @member2,
    '2026-09-27',
    78.60,
    20.8,
    34.5,
    @a9
);


/* =========================================================
   Follow-up
   按建立時間由舊 → 新
   ========================================================= */

-- Follow-up 1：林怡君
INSERT INTO dbo.followup
(membercourseid, coachid, status, note, createdate, contactmethod)
VALUES
(
    @mc3,
    @coachId,
    N'CONSIDERING',
    N'近期工作忙碌，預計下週重新安排課程。',
    '2026-09-20 12:00',
    N'LINE'
);


-- Follow-up 2：張家豪
INSERT INTO dbo.followup
(membercourseid, coachid, status, note, createdate, contactmethod)
VALUES
(
    @mc4,
    @coachId,
    N'DECLINED',
    N'目前因預算考量暫不續約。',
    '2026-09-25 19:00',
    N'IN_PERSON'
);


-- Follow-up 3：陳志豪
INSERT INTO dbo.followup
(membercourseid, coachid, status, note, createdate, contactmethod)
VALUES
(
    @mc2,
    @coachId,
    N'AGREED',
    N'學員已表示願意續約，待確認付款方式。',
    '2026-09-26 16:30',
    N'PHONE'
);


-- Follow-up 4：王小美
INSERT INTO dbo.followup
(membercourseid, coachid, status, note, createdate, contactmethod)
VALUES
(
    @mc1,
    @coachId,
    N'CONSIDERING',
    N'已告知剩餘堂數不多，學員表示會考慮續約。',
    '2026-09-26 18:00',
    N'LINE'
);


-- Follow-up 5：黃雅婷
INSERT INTO dbo.followup
(membercourseid, coachid, status, note, createdate, contactmethod)
VALUES
(
    @mc6,
    @coachId,
    N'NOT_CONTACTED',
    N'尚未聯繫，建議優先關懷。',
    '2026-09-27 09:00',
    N'OTHER'
);


/* =========================================================
   Renewal
   ========================================================= */

INSERT INTO dbo.renewal
(
    membercourseid,
    renewaldate,
    addedsessions,
    amount,
    paymentmethod,
    note
)
VALUES
(
    @mc5,
    '2026-08-15 15:30',
    10,
    15000,
    N'CREDIT_CARD',
    N'暑期續約加購10堂'
);

GO



/* =========================================================
   檢查SQL
   ========================================================= */
SELECT * FROM dbo.member;
SELECT * FROM dbo.membercourse;
SELECT * FROM dbo.classschedule;
SELECT * FROM dbo.booking;
SELECT * FROM dbo.attendance;
SELECT * FROM dbo.inbodyrecords;
SELECT * FROM dbo.followup;
SELECT * FROM dbo.renewal;