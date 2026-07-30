-- ============================================================================
-- Contract-Tests für Identifier- und Multipart-Name-Toolkit
-- Daten: ausschließlich synthetisch
-- SQLCMD-Variable: CompatibilityLevel=150|160|170
-- ============================================================================

SET NOCOUNT ON;

DECLARE @CompatibilityLevel int =
    TRY_CONVERT(int, N'$(CompatibilityLevel)');

IF @CompatibilityLevel NOT IN (150, 160, 170)
BEGIN
    THROW 52500, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
END;

IF
(
    SELECT compatibility_level
    FROM sys.databases
    WHERE database_id = DB_ID()
) <> @CompatibilityLevel
BEGIN
    THROW 52501, N'Der Test benötigt eine neue Session mit dem erwarteten Compatibility Level.', 1;
END;

IF OBJECT_ID(N'toolbelt_metadata.TVF_ParseMultipartName', N'TF') IS NULL
   OR OBJECT_ID(N'toolbelt_metadata.SVF_QuoteMultipartName', N'FN') IS NULL
BEGIN
    THROW 52502, N'Die öffentlichen Identifier-Funktionen fehlen oder besitzen den falschen Typ.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.parameters
       WHERE object_id =
             OBJECT_ID(N'toolbelt_metadata.TVF_ParseMultipartName', N'TF')
         AND parameter_id = 1
         AND name = N'@MultipartName'
         AND TYPE_NAME(user_type_id) = N'nvarchar'
         AND max_length = 2070
   )
   OR NOT EXISTS
      (
          SELECT 1
          FROM sys.parameters
          WHERE object_id =
                OBJECT_ID(N'toolbelt_metadata.SVF_QuoteMultipartName', N'FN')
            AND parameter_id = 1
            AND name = N'@MultipartName'
            AND TYPE_NAME(user_type_id) = N'nvarchar'
            AND max_length = 2070
      )
BEGIN
    THROW 52503, N'Die öffentlichen Parameter weichen vom Vertrag ab.', 1;
END;

DECLARE @ExpectedColumns TABLE
(
      ColumnId   int      NOT NULL
    , ColumnName sysname  NOT NULL
    , TypeName   sysname  NOT NULL
);

INSERT INTO @ExpectedColumns (ColumnId, ColumnName, TypeName)
VALUES
      (1, N'IsValid', N'bit')
    , (2, N'ValidationCode', N'varchar')
    , (3, N'PartCount', N'tinyint')
    , (4, N'ServerName', N'nvarchar')
    , (5, N'DatabaseName', N'nvarchar')
    , (6, N'SchemaName', N'nvarchar')
    , (7, N'ObjectName', N'nvarchar')
    , (8, N'QuotedName', N'nvarchar');

IF EXISTS
   (
       SELECT expected.ColumnId, expected.ColumnName, expected.TypeName
       FROM @ExpectedColumns AS expected
       EXCEPT
       SELECT columns.column_id, columns.name, TYPE_NAME(columns.user_type_id)
       FROM sys.columns AS columns
       WHERE columns.object_id =
             OBJECT_ID(N'toolbelt_metadata.TVF_ParseMultipartName', N'TF')
   )
   OR
   (
       SELECT COUNT(*)
       FROM sys.columns
       WHERE object_id =
             OBJECT_ID(N'toolbelt_metadata.TVF_ParseMultipartName', N'TF')
   ) <> 8
BEGIN
    THROW 52504, N'Das Parser-Resultset weicht vom Vertrag ab.', 1;
END;

DECLARE @ValidCases TABLE
(
      CaseId       int             NOT NULL PRIMARY KEY
    , InputValue   nvarchar(1035)  NOT NULL
    , PartCount    tinyint         NOT NULL
    , ServerName   sysname         NULL
    , DatabaseName sysname         NULL
    , SchemaName   sysname         NULL
    , ObjectName   sysname         NOT NULL
    , QuotedName   nvarchar(1035)  NOT NULL
);

INSERT INTO @ValidCases
(
      CaseId
    , InputValue
    , PartCount
    , ServerName
    , DatabaseName
    , SchemaName
    , ObjectName
    , QuotedName
)
VALUES
      (1, N'Object', 1, NULL, NULL, NULL, N'Object', N'[Object]')
    , (2, N'dbo.Object', 2, NULL, NULL, N'dbo', N'Object', N'[dbo].[Object]')
    , (3, N'Database.dbo.Object', 3, NULL, N'Database', N'dbo', N'Object', N'[Database].[dbo].[Object]')
    , (4, N'Server.Database.dbo.Object', 4, N'Server', N'Database', N'dbo', N'Object', N'[Server].[Database].[dbo].[Object]')
    , (5, N'Database..Object', 3, NULL, N'Database', NULL, N'Object', N'[Database]..[Object]')
    , (6, N'Server.Database..Object', 4, N'Server', N'Database', NULL, N'Object', N'[Server].[Database]..[Object]')
    , (7, N'Server..dbo.Object', 4, N'Server', NULL, N'dbo', N'Object', N'[Server]..[dbo].[Object]')
    , (8, N'Server...Object', 4, N'Server', NULL, NULL, N'Object', N'[Server]...[Object]')
    , (9, N'[Archive.Db].dbo.[Order.Detail]', 3, NULL, N'Archive.Db', N'dbo', N'Order.Detail', N'[Archive.Db].[dbo].[Order.Detail]')
    , (10, N'[Db]]Name].dbo.[Object]]Name]', 3, NULL, N'Db]Name', N'dbo', N'Object]Name', N'[Db]]Name].[dbo].[Object]]Name]');

IF EXISTS
   (
       SELECT
             expected.CaseId
           , expected.PartCount
           , expected.ServerName
           , expected.DatabaseName
           , expected.SchemaName
           , expected.ObjectName
           , expected.QuotedName
       FROM @ValidCases AS expected
       EXCEPT
       SELECT
             expected.CaseId
           , parsed.PartCount
           , parsed.ServerName
           , parsed.DatabaseName
           , parsed.SchemaName
           , parsed.ObjectName
           , parsed.QuotedName
       FROM @ValidCases AS expected
       CROSS APPLY
            toolbelt_metadata.TVF_ParseMultipartName(expected.InputValue)
                AS parsed
       WHERE parsed.IsValid = 1
         AND parsed.ValidationCode = 'VALID'
   )
BEGIN
    THROW 52505, N'Mindestens ein gültiger Multipart-Fall wurde falsch analysiert.', 1;
END;

IF EXISTS
   (
       SELECT 1
       FROM @ValidCases AS expected
       CROSS APPLY
            toolbelt_metadata.TVF_ParseMultipartName(expected.InputValue)
                AS parsed
       WHERE parsed.QuotedName
             <> toolbelt_metadata.SVF_QuoteMultipartName(expected.InputValue)
   )
BEGIN
    THROW 52506, N'Der Scalar-Wrapper weicht vom kanonischen Parser ab.', 1;
END;

DECLARE @InvalidCases TABLE
(
      CaseId         int             NOT NULL PRIMARY KEY
    , InputValue     nvarchar(1035)  NULL
    , ValidationCode varchar(32)     NOT NULL
);

INSERT INTO @InvalidCases (CaseId, InputValue, ValidationCode)
VALUES
      (1, NULL, 'NULL_INPUT')
    , (2, N'', 'EMPTY_INPUT')
    , (3, N'.Object', 'INVALID_OMISSION')
    , (4, N'dbo.', 'INVALID_OMISSION')
    , (5, N'a.b.c.d.e', 'TOO_MANY_PARTS')
    , (6, N'[Object', 'UNCLOSED_DELIMITER')
    , (7, N'[Object]x', 'TEXT_AFTER_DELIMITER')
    , (8, N'dbo.Obj*', 'UNQUOTED_META_CHARACTER')
    , (9, N' dbo.Object', 'OUTER_WHITESPACE')
    , (10, N'dbo.[]', 'EMPTY_IDENTIFIER')
    , (11, N'a[b].Object', 'BRACKET_SYNTAX')
    , (12, N'dbo.' + NCHAR(9) + N'Object', 'CONTROL_CHARACTER')
    , (13, N'"dbo"."Object"', 'UNQUOTED_META_CHARACTER');

IF EXISTS
   (
       SELECT expected.CaseId, expected.ValidationCode
       FROM @InvalidCases AS expected
       EXCEPT
       SELECT expected.CaseId, parsed.ValidationCode
       FROM @InvalidCases AS expected
       CROSS APPLY
            toolbelt_metadata.TVF_ParseMultipartName(expected.InputValue)
                AS parsed
       WHERE parsed.IsValid = 0
         AND parsed.QuotedName IS NULL
         AND parsed.ServerName IS NULL
         AND parsed.DatabaseName IS NULL
         AND parsed.SchemaName IS NULL
         AND parsed.ObjectName IS NULL
   )
BEGIN
    THROW 52507, N'Mindestens ein ungültiger Multipart-Fall besitzt einen falschen Status.', 1;
END;

IF EXISTS
   (
       SELECT 1
       FROM @InvalidCases
       WHERE toolbelt_metadata.SVF_QuoteMultipartName(InputValue) IS NOT NULL
   )
BEGIN
    THROW 52508, N'Der Scalar-Wrapper akzeptiert eine ungültige Eingabe.', 1;
END;

DECLARE
      @Part128 nvarchar(128) = REPLICATE(N'x', 128)
    , @Part129 nvarchar(129) = REPLICATE(N'x', 129);

IF toolbelt_metadata.SVF_QuoteMultipartName(@Part128)
       <> N'[' + @Part128 + N']'
BEGIN
    THROW 52509, N'Die 128-Zeichen-Grenze wird falsch behandelt.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_metadata.TVF_ParseMultipartName(@Part129)
       WHERE IsValid = 0
         AND ValidationCode = 'PART_TOO_LONG'
   )
BEGIN
    THROW 52510, N'Ein Identifier mit 129 Zeichen wurde nicht abgelehnt.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_metadata.TVF_ParseMultipartName(N'NoSuchDb.NoSuchSchema.NoSuchObject')
       WHERE IsValid = 1
   )
BEGIN
    THROW 52511, N'Der Parser führt unerlaubt eine Objektauflösung aus.', 1;
END;

PRINT N'Identifier-Contract erfolgreich.';
