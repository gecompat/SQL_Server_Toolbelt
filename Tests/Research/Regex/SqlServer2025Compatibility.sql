SET NOCOUNT ON;

DECLARE @CompatibilityLevel int = TRY_CONVERT(int, N'$(CompatibilityLevel)');
IF TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion')) <> 17
    THROW 53070, N'Der native Regex-Kompatibilitätsspike benötigt SQL Server 2025.', 1;
IF @CompatibilityLevel NOT IN (150, 160, 170)
    THROW 53071, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID())
       <> @CompatibilityLevel
    THROW 53072, N'Der aktive Compatibility Level ist falsch.', 1;

IF REGEXP_INSTR(N'abc123', N'[0-9]+') <> 4
   OR REGEXP_INSTR(N'AbC', N'^abc$', 1, 1, 0, 'i') <> 1
   OR REGEXP_INSTR(N'a' + NCHAR(10) + N'b', N'a.b', 1, 1, 1, 's') <> 4
   OR REGEXP_COUNT(N'aaaa', N'aa') <> 2
   OR REGEXP_COUNT(N'ab', N'') <> 3
    THROW 53073, N'REGEXP_INSTR oder REGEXP_COUNT ist semantisch gedriftet.', 1;

DECLARE @LikeAvailable bit = 1;
BEGIN TRY
    EXEC sys.sp_executesql
         N'IF NOT REGEXP_LIKE(N''abc'', N''^abc$'') THROW 53074, N''REGEXP_LIKE lieferte ein falsches Ergebnis.'', 1;';
END TRY
BEGIN CATCH
    SET @LikeAvailable = 0;
END CATCH;

IF @CompatibilityLevel = 170 AND @LikeAvailable = 0
    THROW 53075, N'REGEXP_LIKE fehlt bei Compatibility Level 170.', 1;
IF @CompatibilityLevel IN (150, 160) AND @LikeAvailable = 1
    THROW 53076, N'REGEXP_LIKE war unerwartet unterhalb Compatibility Level 170 verfügbar.', 1;

PRINT N'R1a SQL Server 2025 Compatibility-Semantik: erfolgreich';
GO
