USE gymproject;
GO
-- 教練資料表
CREATE TABLE coach (
    coachid INT IDENTITY(1,1) PRIMARY KEY, --教練ID，自動編號
    accountid INT NULL,                     -- 對應登入帳號的ID，帳號表確定後再設定外鍵
    coachno VARCHAR(20) NOT NULL UNIQUE,    -- 教練編號，不可重複
    [name] NVARCHAR(50) NOT NULL,           -- 教練姓名
    gender NVARCHAR(10) NULL,                -- 性別
    phone VARCHAR(20) NULL,                  -- 電話
    email VARCHAR(100) NULL,                 -- 電子郵件
    specialty NVARCHAR(200) NULL,            -- 專長
    [status] NVARCHAR(20) NOT NULL            -- 教練狀態
        CONSTRAINT dfcoachstatus DEFAULT N'在職'
);
GO
-- 課程資料表
CREATE TABLE course (
    courseid INT IDENTITY(1,1) PRIMARY KEY, -- 課程ID，自動編號
    coursename NVARCHAR(100) NOT NULL,       -- 課程名稱
    coursetype NVARCHAR(50) NOT NULL,        -- 課程類型
    [description] NVARCHAR(500) NULL,          -- 課程介紹
    durationmin INT NOT NULL                 -- 每堂課的時長，單位為分鐘
        CONSTRAINT dfcoursedurationmin DEFAULT 60, -- 未填時自動設為 60 分鐘
    price DECIMAL(10, 2) NOT NULL,            -- 課程價格
    [status] NVARCHAR(20) NOT NULL             -- 課程狀態
        CONSTRAINT dfcoursestatus DEFAULT N'上架',

    CONSTRAINT ckcoursedurationmin
        CHECK (durationmin = 60),-- 每堂課時長只能是 60 分鐘

    CONSTRAINT ckcourseprice
        CHECK (price >= 0)       -- 課程價格不可為負數
);
GO
-- 教練與課程的關聯表
CREATE TABLE coachcourse (
    coachid INT NOT NULL,  -- 教練ID，對應 coach.coachid
    courseid INT NOT NULL, -- 課程ID，對應 course.courseid

    -- 複合主鍵：避免同一位教練重複綁定同一門課
    CONSTRAINT pkcoachcourse
        PRIMARY KEY (coachid, courseid),

    -- coachid 關聯 coach
    CONSTRAINT fkcoachcoursecoach
        FOREIGN KEY (coachID)
        REFERENCES coach(coachid),

    -- courseid 關聯 course
    CONSTRAINT fkcoachcoursecourse
        FOREIGN KEY (courseid)
        REFERENCES course(courseid)
);
GO
