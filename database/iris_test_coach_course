USE gymproject;
GO

INSERT INTO course (coursename, coursetype, [description], price)
VALUES
    (N'初階重訓', N'重量訓練', N'適合初學者的重量訓練課程，每堂 60 分鐘。', 800.00),
    (N'中階重訓', N'重量訓練', N'適合已有基礎、想進一步提升肌力的學員。', 1000.00),
    (N'高階重訓', N'重量訓練', N'適合有訓練經驗、想挑戰較高強度的學員。', 1200.00),
    (N'筋膜放鬆', N'伸展放鬆', N'透過筋膜放鬆練習，舒緩運動後的緊繃感。', 700.00),
    (N'TRX', N'懸吊訓練', N'利用懸吊器材進行全身肌力與核心訓練。', 900.00);
GO

SELECT * FROM course;

INSERT INTO coach (coachno, [name])
VALUES
    ('C001', N'AMY'),
    ('C002', N'BEN'),
    ('C003', N'CHRIS'),
    ('C004', N'DAVID'),
    ('C005', N'ERIC');
GO
INSERT INTO coachcourse (coachid, courseid)
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
JOIN coach AS c ON c.coachno = mapping.coachno
JOIN course AS co ON co.coursename = mapping.coursename;
GO
SELECT
    c.coachno,
    c.[name] AS coachname,
    c.[status],
    co.coursename
FROM coachcourse AS cc
JOIN coach AS c ON c.coachid = cc.coachid
JOIN course AS co ON co.courseid = cc.courseid
ORDER BY c.coachno, co.courseid;
