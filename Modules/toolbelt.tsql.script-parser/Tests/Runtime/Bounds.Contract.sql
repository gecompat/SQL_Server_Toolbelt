SET NOCOUNT ON;

-- Gemeinsamer Fehlervertrag: jeder Fall läuft durch alle vier Einstiegspunkte.
DECLARE @Cases table
(
    CaseId int IDENTITY PRIMARY KEY, SqlText nvarchar(max), TSqlVersion int,
    MaxBytes int, MaxDepth int, Prefix nvarchar(128), EmptyExpected bit
);
INSERT @Cases (SqlText, TSqlVersion, MaxBytes, MaxDepth, Prefix, EmptyExpected)
VALUES
 (NULL, 999, 0, 0, NULL, 1),
 (N'SELECT 1;', 999, 0, 0, N'TBX_TSQLPARSE_INVALID_VERSION', 0),
 (N'SELECT 1;', 160, 0, 0, N'TBX_TSQLPARSE_INVALID_MAX_BYTES', 0),
 (N'SELECT 1;', 160, 2097153, 100, N'TBX_TSQLPARSE_INVALID_MAX_BYTES', 0),
 (N'SELECT 1;', 160, 2097152, 0, N'TBX_TSQLPARSE_INVALID_MAX_DEPTH', 0),
 (N'SELECT 1;', 160, 2097152, 257, N'TBX_TSQLPARSE_INVALID_MAX_DEPTH', 0),
 (N'SELECT 1;', 160, 2, 100, N'TBX_TSQLPARSE_INPUT_TOO_LARGE', 0),
 (REPLICATE(CAST(N' ' AS nvarchar(max)), 8193), 160, NULL, NULL, N'TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT', 0),
 (N'SELECT ' + REPLICATE(CAST(N'(' AS nvarchar(max)), 33) + N'1' + REPLICATE(CAST(N')' AS nvarchar(max)), 33), 160, NULL, NULL, N'TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT', 0),
 (N'SELECT 1;' + REPLICATE(CAST(N';' AS nvarchar(max)), 510), 160, NULL, NULL, N'TBX_TSQLPARSE_PREPARSE_COMPLEXITY_LIMIT', 0);
INSERT @Cases (SqlText, TSqlVersion, MaxBytes, MaxDepth, Prefix, EmptyExpected)
VALUES (REPLICATE(CAST(N' ' AS nvarchar(max)), 1048577), NULL, NULL, NULL, N'TBX_TSQLPARSE_INPUT_TOO_LARGE', 0);

DECLARE @Functions table (FunctionId int IDENTITY PRIMARY KEY, Name sysname);
INSERT @Functions (Name) VALUES (N'TVF_ParseScriptNodes'), (N'TVF_ParseScriptNodeProperties'), (N'TVF_TokenizeScript'), (N'TVF_ParseScriptErrors');
DECLARE @FunctionId int = 1, @CaseId int, @Name sysname, @Sql nvarchar(max), @Text nvarchar(max),
        @Version int, @Bytes int, @Depth int, @Prefix nvarchar(128), @Empty bit, @Count bigint, @Caught bit;
WHILE @FunctionId <= 4
BEGIN
    SELECT @Name = Name FROM @Functions WHERE FunctionId = @FunctionId;
    SET @Sql = N'SELECT @Count = COUNT_BIG(*) FROM toolbelt_tsql.' + QUOTENAME(@Name) + N'(@Text, @Version, 1, @Bytes, @Depth);';
    SET @CaseId = 1;
    WHILE @CaseId <= (SELECT COUNT(*) FROM @Cases)
    BEGIN
        SELECT @Text = SqlText, @Version = TSqlVersion, @Bytes = MaxBytes, @Depth = MaxDepth,
               @Prefix = Prefix, @Empty = EmptyExpected FROM @Cases WHERE CaseId = @CaseId;
        SET @Caught = 0;
        SET @Count = NULL;
        BEGIN TRY
            EXEC sys.sp_executesql @Sql, N'@Text nvarchar(max), @Version int, @Bytes int, @Depth int, @Count bigint OUTPUT',
                 @Text, @Version, @Bytes, @Depth, @Count OUTPUT;
        END TRY
        BEGIN CATCH
            IF @Prefix IS NULL OR CHARINDEX(@Prefix, ERROR_MESSAGE()) = 0 OR ERROR_NUMBER() <> 6522
                THROW;
            SET @Caught = 1;
        END CATCH;
        IF @Prefix IS NOT NULL AND @Caught = 0
            THROW 53130, N'Ein gemeinsamer Grenzfehler wurde nicht ausgelöst.', 1;
        IF @Empty = 1 AND (@Caught <> 0 OR @Count <> 0 OR @Count IS NULL)
            THROW 53130, N'NULL-Text besitzt nicht die vereinbarte Fehlerpriorität.', 2;
        SET @CaseId += 1;
    END;
    SET @FunctionId += 1;
END;

-- AST-Tiefe und lexikalische Tiefe sind absichtlich verschiedene Verträge.
SET @FunctionId = 1;
WHILE @FunctionId <= 4
BEGIN
    IF @FunctionId <> 3
    BEGIN
        SELECT @Name = Name FROM @Functions WHERE FunctionId = @FunctionId;
        SET @Sql = N'SELECT @Count = COUNT_BIG(*) FROM toolbelt_tsql.' + QUOTENAME(@Name) + N'(N''SELECT 1;'', 160, 1, 2097152, 1);';
        SET @Caught = 0;
        BEGIN TRY
            EXEC sys.sp_executesql @Sql, N'@Count bigint OUTPUT', @Count OUTPUT;
        END TRY
        BEGIN CATCH
            IF ERROR_NUMBER() <> 6522 OR CHARINDEX(N'TBX_TSQLPARSE_MAX_DEPTH_EXCEEDED', ERROR_MESSAGE()) = 0 THROW;
            SET @Caught = 1;
        END CATCH;
        IF @Caught = 0 THROW 53130, N'Die AST-Tiefengrenze wurde nicht geprüft.', 8;
    END;
    SET @FunctionId += 1;
END;
IF NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_TokenizeScript(N'SELECT 1;', 160, 1, 2097152, 1))
    THROW 53130, N'Tokenize prüfte fälschlich die AST-Tiefe.', 9;

-- Syntaxfehler dürfen keinen partiellen AST liefern; Tokenize bleibt lexikalisch.
IF EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodes(N'SELECT 1; SELECT FROM;', NULL, NULL, NULL, NULL))
 OR EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptNodeProperties(N'SELECT 1; SELECT FROM;', NULL, NULL, NULL, NULL))
    THROW 53130, N'Syntaxfehler lieferten einen partiellen AST.', 3;
IF NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_ParseScriptErrors(N'SELECT 1; SELECT FROM;', NULL, NULL, NULL, NULL))
    THROW 53130, N'Die Syntaxdiagnose fehlt.', 4;
IF NOT EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_TokenizeScript(N'SELECT FROM;', NULL, NULL, NULL, NULL))
    THROW 53130, N'Tokenize führte unzulässigerweise eine Grammatikprüfung aus.', 5;
IF EXISTS (SELECT 1 FROM toolbelt_tsql.TVF_TokenizeScript(N'SELECT ''offen', NULL, NULL, NULL, NULL))
    THROW 53130, N'Tokenize lieferte Tokens trotz lexikalischem Fehler.', 6;

DECLARE @RoundtripInput nvarchar(max) = N'SELECT N''ä😀'' AS [a]]b]; /* '' [ */' + NCHAR(13) + NCHAR(10);
DECLARE @Roundtrip nvarchar(max);
SELECT @Roundtrip = STRING_AGG(CONVERT(nvarchar(max), TokenText), N'') WITHIN GROUP (ORDER BY TokenIndex)
FROM toolbelt_tsql.TVF_TokenizeScript(@RoundtripInput, NULL, NULL, NULL, NULL);
IF @Roundtrip IS NULL OR CONVERT(varbinary(max), @Roundtrip) <> CONVERT(varbinary(max), @RoundtripInput)
    THROW 53130, N'Der UTF-16-Token-Roundtrip ist nicht verlustfrei.', 7;

PRINT N'ScriptParser-Grenzvertrag erfolgreich.';
