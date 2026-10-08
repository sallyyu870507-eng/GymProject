USE GymProject;
GO

/*classschedule
✓ 同教練同一天同時間不能重複
✓ 一堂固定 60 分鐘
✓ status 只能 open / closed

booking
✓ 同一 schedule 只能有一筆 booked
✓ bookingstatus 只能 booked / cancelled / completed*/

/*同一個教練在同一天同一時間只能有一筆課表*/

ALTER TABLE dbo.classschedule
ADD CONSTRAINT UQ_classschedule_coach_datetime
UNIQUE (coachid,classdate,starttime);
/*三個表建在一起不能重複*/
GO


/*一堂課固定1個小時*/
ALTER TABLE dbo.classschedule
ADD CONSTRAINT CK_classschedule_one_hour
CHECK (DATEDIFF(MINUTE,starttime,endtime)=60);
/*用分鐘去計算STARTTIME到ENDTIME差多少*/
GO

/*同一個時段不能被兩個人同時預約*/
CREATE UNIQUE INDEX UQ_booking_active_schedule
ON dbo.booking(scheduleid)
WHERE bookingstatus = N'booked';
GO

/*booking.bookingstatus
booked     = 已預約
cancelled  = 已取消
completed  = 已完成*/
ALTER TABLE dbo.booking
ADD CONSTRAINT CK_booking_status
CHECK (bookingstatus IN (N'booked', N'cancelled', N'completed'));
GO

/*classschedule.status
open      = 可預約
closed    = 關閉，不可預約*/
ALTER TABLE dbo.classschedule
ADD CONSTRAINT CK_classschedule_status
CHECK (status IN (N'open', N'closed'));
GO

