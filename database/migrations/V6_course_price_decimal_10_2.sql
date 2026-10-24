/*
適用前提：
- 目前資料庫必須是 gymproject。
- dbo.course.price 必須為 int NOT NULL。
- 既有價格必須可由 decimal(10,2) 表示。
- CK_course_values 必須啟用且受信任，且定義等同 durationmin > 0 AND price >= 0。
- 本機已由使用者執行並確認：5 筆資料保留，price 為 decimal(10,2) NOT NULL，
  CK_course_values 已以相同規則重建、啟用且受信任。

本檔僅保存已審閱的遷移及驗證 SQL；本次建立文件時沒有執行 SQL。
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() <> N'gymproject'
    THROW 51000, '目前資料庫不是 gymproject；已停止，未進行變更。', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @course_object_id int = OBJECT_ID(N'dbo.course', N'U');
    DECLARE @price_column_id int;
    DECLARE @price_type sysname;
    DECLARE @price_nullable bit;
    DECLARE @constraint_definition nvarchar(max);
    DECLARE @constraint_disabled bit;
    DECLARE @constraint_not_trusted bit;

    IF @course_object_id IS NULL
        THROW 51001, '找不到 dbo.course；已停止。', 1;

    SELECT
        @price_column_id = c.column_id,
        @price_type = ty.name,
        @price_nullable = c.is_nullable
    FROM sys.columns c
    JOIN sys.types ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = @course_object_id
      AND c.name = N'price';

    IF @price_column_id IS NULL
        THROW 51002, '找不到 dbo.course.price；已停止。', 1;

    IF @price_type <> N'int' OR @price_nullable <> 0
        THROW 51003, 'dbo.course.price 並非預期的 int NOT NULL；已停止。', 1;

    IF EXISTS (
        SELECT 1
        FROM dbo.course
        WHERE price IS NULL
           OR price < -99999999
           OR price > 99999999
    )
        THROW 51004, '價格有空值或超出 decimal(10,2) 範圍；已停止，未轉型資料。', 1;

    SELECT
        @constraint_definition = cc.definition,
        @constraint_disabled = cc.is_disabled,
        @constraint_not_trusted = cc.is_not_trusted
    FROM sys.check_constraints cc
    WHERE cc.parent_object_id = @course_object_id
      AND cc.name = N'CK_course_values';

    IF @constraint_definition IS NULL
        THROW 51005, '找不到預期的 CK_course_values；已停止。', 1;

    -- 正規化空白及括號後比較定義，不接受未審閱的不同規則。
    DECLARE @normalized_definition nvarchar(max) =
        LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
            @constraint_definition,
            N' ', N''), CHAR(9), N''), CHAR(10), N''), CHAR(13), N''), N'(', N''));

    SET @normalized_definition = REPLACE(@normalized_definition, N')', N'');

    IF @normalized_definition NOT IN (
        N'[durationmin]>0and[price]>=0',
        N'[price]>=0and[durationmin]>0'
    )
        THROW 51006, 'CK_course_values 定義與預期不同；已停止。', 1;

    IF @constraint_disabled <> 0 OR @constraint_not_trusted <> 0
        THROW 51007, 'CK_course_values 未啟用或未受信任；已停止。', 1;

    ALTER TABLE dbo.course
        DROP CONSTRAINT CK_course_values;

    ALTER TABLE dbo.course
        ALTER COLUMN price decimal(10,2) NOT NULL;

    ALTER TABLE dbo.course WITH CHECK
        ADD CONSTRAINT CK_course_values
        CHECK (durationmin > 0 AND price >= 0);

    ALTER TABLE dbo.course
        CHECK CONSTRAINT CK_course_values;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO

-- 遷移後確認資料庫、price 欄位型別與可空性。
SELECT
    DB_NAME() AS current_database,
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE s.name = N'dbo'
  AND t.name = N'course'
  AND c.name = N'price';

-- 遷移後確認價格筆數、範圍及空值。
SELECT
    COUNT_BIG(*) AS row_count,
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS null_count,
    SUM(CASE
          WHEN price < CONVERT(decimal(10,2), -99999999)
            OR price > CONVERT(decimal(10,2),  99999999)
          THEN 1 ELSE 0
        END) AS outside_decimal_10_2_range_count
FROM dbo.course;

-- 遷移後確認約束定義、啟用與信任狀態。
SELECT
    cc.name AS constraint_name,
    cc.definition,
    cc.is_disabled,
    cc.is_not_trusted
FROM sys.check_constraints cc
WHERE cc.parent_object_id = OBJECT_ID(N'dbo.course', N'U')
  AND cc.name = N'CK_course_values';
