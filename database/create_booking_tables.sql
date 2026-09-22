USE GymProject;
GO

CREATE TABLE dbo.booking (
    bookingid INT IDENTITY(1,1) PRIMARY KEY,

    scheduleid INT NOT NULL,
    memberid INT NOT NULL,

    bookingtime DATETIME2 NOT NULL
    /*會員按下預約的時間*/
        CONSTRAINT df_booking_bookingtime 
        DEFAULT GETDATE(),

    [status] NVARCHAR(20) NOT NULL
    /*預約的狀態*/
        CONSTRAINT df_booking_status 
        DEFAULT N'已預約',

    CONSTRAINT fk_booking_schedule
        FOREIGN KEY (scheduleid)
        REFERENCES dbo.classschedule(scheduleid),

    CONSTRAINT ck_booking_status
        CHECK ([status] IN (N'已預約', N'已取消', N'已完成'))
);
GO

	CREATE UNIQUE INDEX uq_booking_active_schedule
	/*同一個時段，同時間只能存在一筆「已預約」*/
	ON dbo.booking(scheduleid)
	WHERE [status]=N'已預約';
	GO