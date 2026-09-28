USE gym;
GO

--attendance.updatetime：新增最後修改時間
ALTER TABLE dbo.attendance
ADD updatetime DATETIME NULL;
GO


--attendance.bookingid：設定 UNIQUE (一筆 Booking 最多只能有一筆 Attendance)
ALTER TABLE dbo.attendance
ADD CONSTRAINT UQ_attendance_bookingid
UNIQUE (bookingid);
GO

--attendance.attendancestatus:修改預設值
ALTER TABLE dbo.attendance
DROP CONSTRAINT DF_attendance_attendancestatus;
GO

ALTER TABLE dbo.attendance
ADD CONSTRAINT DF_attendance_attendancestatus
DEFAULT (N'PENDING') FOR attendancestatus;
GO


--renewal.note：新增續約備註
ALTER TABLE dbo.renewal
ADD note NVARCHAR(500) NULL;
GO


--followup.contactmethod：新增聯絡方式 (可存 LINE / PHONE / IN_PERSON / OTHER)
ALTER TABLE dbo.followup
ADD contactmethod NVARCHAR(20) NULL;
GO

--followup.urgencytag:刪除流失風險標籤
ALTER TABLE dbo.followup
DROP COLUMN urgencytag;
GO

--followup.createdate:修改欄位名稱
EXEC sp_rename 
    'dbo.followup.createdat', 
    'createdate', 
    'COLUMN';
GO

--inbodyrecords：新增 attendanceid (用來記錄這筆 InBody 是由哪次出席建立)
ALTER TABLE dbo.inbodyrecords
ALTER COLUMN attendanceid INT NOT NULL;
GO
 
ALTER TABLE dbo.inbodyrecords
ADD CONSTRAINT FK_inbodyrecords_attendance
FOREIGN KEY (attendanceid)
REFERENCES dbo.attendance(attendanceid);
GO


-- member：新增會員頭像路徑 (資料庫只存路徑 / URL，不存圖片本身)
ALTER TABLE dbo.member
ADD avatarurl NVARCHAR(500) NULL;
GO

--檢查修改的table
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN (
    'attendance',
    'renewal',
    'followup',
    'inbodyrecords',
    'member'
)
ORDER BY TABLE_NAME, ORDINAL_POSITION;


-- 看 UNIQUE / FK / DEFAULT 等 constraint
SELECT 
    t.name AS table_name,
    o.name AS constraint_name,
    o.type_desc
FROM sys.objects o
JOIN sys.tables t
    ON o.parent_object_id = t.object_id
WHERE t.name IN ('attendance', 'followup', 'inbodyrecords', 'renewal', 'member')
ORDER BY t.name, o.type_desc;