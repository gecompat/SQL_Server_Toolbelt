SET NOCOUNT ON;

IF TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion')) <> 17
    THROW 53080, N'Der native Regex-Spike benötigt SQL Server 2025.', 1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID()) <> 170
    THROW 53081, N'Der native Regex-Spike benötigt Compatibility Level 170.', 1;

DECLARE @Cases TABLE
(
      CaseId        varchar(32)    NOT NULL PRIMARY KEY
    , InputValue    nvarchar(100)  NOT NULL
    , PatternValue  nvarchar(100)  NOT NULL
    , FlagsValue    varchar(4)     NOT NULL
    , ExpectedLike  bit            NOT NULL
    , ExpectedStart int            NOT NULL
    , ExpectedEnd   int            NOT NULL
    , ExpectedCount int            NOT NULL
);

INSERT INTO @Cases
    (CaseId, InputValue, PatternValue, FlagsValue,
     ExpectedLike, ExpectedStart, ExpectedEnd, ExpectedCount)
VALUES
      ('basic',           N'abc123', N'[0-9]+',    'c', 1, 4, 7, 1)
    , ('case-sensitive',  N'AbC',    N'^abc$',     'c', 0, 0, 0, 0)
    , ('case-insensitive',N'AbC',    N'^abc$',     'i', 1, 1, 4, 1)
    , ('ascii-word',      N'é',      N'^\w+$',     'c', 0, 0, 0, 0)
    , ('unicode-letter',  N'é',      N'^\p{L}+$',  'c', 1, 1, 2, 1)
    , ('alternation',     N'ab',     N'a|ab',      'c', 1, 1, 2, 1)
    , ('greedy',          N'a1b2b',  N'a.*b',      'c', 1, 1, 6, 1)
    , ('lazy',            N'a1b2b',  N'a.*?b',     'c', 1, 1, 4, 1)
    , ('dot-no-newline',  N'a' + NCHAR(10) + N'b', N'a.b', 'c', 0, 0, 0, 0)
    , ('dot-singleline',  N'a' + NCHAR(10) + N'b', N'a.b', 's', 1, 1, 4, 1)
    , ('multiline',       N'a' + NCHAR(10) + N'b', N'^b$',  'm', 1, 3, 4, 1)
    , ('final-newline',   N'b' + NCHAR(10), N'b$', 'c', 0, 0, 0, 0)
    , ('non-overlap',     N'aaaa',   N'aa',        'c', 1, 1, 3, 2)
    , ('empty-pattern',   N'ab',     N'',          'c', 1, 1, 1, 3)
    , ('emoji-position',  N'a😀b',   N'b',         'c', 1, 4, 5, 1);

DECLARE @Actual TABLE
(
      CaseId     varchar(32) NOT NULL PRIMARY KEY
    , ActualLike bit         NULL
    , ActualStart int        NULL
    , ActualEnd int          NULL
    , ActualCount int        NULL
);

INSERT INTO @Actual (CaseId, ActualLike, ActualStart, ActualEnd, ActualCount)
SELECT
      cases.CaseId
    , CASE
          WHEN REGEXP_LIKE(cases.InputValue, cases.PatternValue,
                           cases.FlagsValue) THEN CONVERT(bit, 1)
          WHEN NOT REGEXP_LIKE(cases.InputValue, cases.PatternValue,
                               cases.FlagsValue) THEN CONVERT(bit, 0)
      END
    , REGEXP_INSTR(cases.InputValue, cases.PatternValue, 1, 1, 0,
                   cases.FlagsValue)
    , REGEXP_INSTR(cases.InputValue, cases.PatternValue, 1, 1, 1,
                   cases.FlagsValue)
    , REGEXP_COUNT(cases.InputValue, cases.PatternValue, 1, cases.FlagsValue)
FROM @Cases AS cases;

IF EXISTS
   (
       SELECT 1
       FROM @Cases AS expected
       JOIN @Actual AS actual ON actual.CaseId = expected.CaseId
       WHERE actual.ActualLike <> expected.ExpectedLike
          OR actual.ActualStart <> expected.ExpectedStart
          OR actual.ActualEnd <> expected.ExpectedEnd
          OR actual.ActualCount <> expected.ExpectedCount
   )
BEGIN
    SELECT
          expected.CaseId
        , expected.ExpectedLike, actual.ActualLike
        , expected.ExpectedStart, actual.ActualStart
        , expected.ExpectedEnd, actual.ActualEnd
        , expected.ExpectedCount, actual.ActualCount
    FROM @Cases AS expected
    JOIN @Actual AS actual ON actual.CaseId = expected.CaseId
    WHERE actual.ActualLike <> expected.ExpectedLike
       OR actual.ActualStart <> expected.ExpectedStart
       OR actual.ActualEnd <> expected.ExpectedEnd
       OR actual.ActualCount <> expected.ExpectedCount;
    THROW 53082, N'Die native SQL-Server-2025-Regex-Semantik ist gedriftet.', 1;
END;

IF EXISTS
   (
       SELECT 1
       WHERE REGEXP_LIKE(NULL, N'a')
          OR NOT REGEXP_LIKE(NULL, N'a')
   )
   OR REGEXP_INSTR(NULL, N'a') IS NOT NULL
   OR REGEXP_COUNT(NULL, N'a') IS NOT NULL
   OR REGEXP_COUNT(N'abc', N'a', 5) <> 0
    THROW 53083, N'Der NULL- oder Startpositionsvertrag ist falsch.', 1;

DECLARE @Rejected int = 0;

BEGIN TRY
    EXEC sys.sp_executesql
         N'IF REGEXP_LIKE(N''aa'', N''(a)\1'') PRINT N''unexpected'';';
END TRY
BEGIN CATCH
    SET @Rejected += 1;
END CATCH;

BEGIN TRY
    EXEC sys.sp_executesql
         N'IF REGEXP_LIKE(N''ab'', N''a(?=b)'') PRINT N''unexpected'';';
END TRY
BEGIN CATCH
    SET @Rejected += 1;
END CATCH;

BEGIN TRY
    EXEC sys.sp_executesql
         N'IF REGEXP_LIKE(N''a'', N''a{1001}'') PRINT N''unexpected'';';
END TRY
BEGIN CATCH
    SET @Rejected += 1;
END CATCH;

BEGIN TRY
    EXEC sys.sp_executesql
         N'IF REGEXP_LIKE(N''a'', N''a'', ''x'') PRINT N''unexpected'';';
END TRY
BEGIN CATCH
    SET @Rejected += 1;
END CATCH;

BEGIN TRY
    EXEC sys.sp_executesql
         N'DECLARE @IgnoredStart int = REGEXP_INSTR(N''a'', N''a'', 0);';
END TRY
BEGIN CATCH
    SET @Rejected += 1;
END CATCH;

IF @Rejected <> 5
    THROW 53084, N'Ein erwarteter nativer Fehlervertrag wurde nicht erzwungen.', 1;

PRINT N'R1a SQL Server 2025 native Semantik: erfolgreich';
GO
