SET NOCOUNT ON;

DECLARE @CompatibilityLevel int = TRY_CONVERT(int, N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN (150, 160, 170)
    THROW 52930, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID())
       <> @CompatibilityLevel
    THROW 52931, N'Falscher Compatibility Level.', 1;

IF OBJECT_ID(N'toolbelt_file.USP_LoadBinaryFile', N'P') IS NULL
    THROW 52932, N'USP_LoadBinaryFile fehlt oder besitzt den falschen Typ.', 1;
IF OBJECT_ID(N'toolbelt_file.USP_LoadTextFile', N'P') IS NULL
    THROW 52932, N'USP_LoadTextFile fehlt oder besitzt den falschen Typ.', 1;

DECLARE @Parameters TABLE
(
      ParameterId int NOT NULL
    , ParameterName sysname NOT NULL
    , TypeName sysname NOT NULL
    , MaxLength smallint NOT NULL
);

INSERT INTO @Parameters (ParameterId, ParameterName, TypeName, MaxLength)
SELECT
      parameters.parameter_id
    , parameters.name
    , types.name
    , parameters.max_length
FROM sys.parameters AS parameters
INNER JOIN sys.types AS types
    ON types.user_type_id = parameters.user_type_id
WHERE parameters.object_id =
      OBJECT_ID(N'toolbelt_file.USP_LoadBinaryFile');

IF (SELECT COUNT(*) FROM @Parameters) <> 4
   OR NOT EXISTS
      (
          SELECT 1 FROM @Parameters
          WHERE ParameterId = 1 AND ParameterName = N'@FilePath'
            AND TypeName = N'nvarchar' AND MaxLength = -1
      )
   OR NOT EXISTS
      (
          SELECT 1 FROM @Parameters
          WHERE ParameterId = 2 AND ParameterName = N'@MaxBytes'
            AND TypeName = N'bigint'
      )
   OR NOT EXISTS
      (
          SELECT 1 FROM @Parameters
          WHERE ParameterId = 3 AND ParameterName = N'@Debug'
            AND TypeName = N'tinyint'
      )
   OR NOT EXISTS
      (
          SELECT 1 FROM @Parameters
          WHERE ParameterId = 4 AND ParameterName = N'@Hilfe'
            AND TypeName = N'bit'
      )
    THROW 52933, N'Die öffentliche LoadBinaryFile-Signatur ist falsch.', 1;

DELETE FROM @Parameters;

INSERT INTO @Parameters (ParameterId, ParameterName, TypeName, MaxLength)
SELECT
      parameters.parameter_id
    , parameters.name
    , types.name
    , parameters.max_length
FROM sys.parameters AS parameters
INNER JOIN sys.types AS types
    ON types.user_type_id = parameters.user_type_id
WHERE parameters.object_id =
      OBJECT_ID(N'toolbelt_file.USP_LoadTextFile');

IF (SELECT COUNT(*) FROM @Parameters) <> 5
   OR NOT EXISTS
      (
          SELECT 1 FROM @Parameters
          WHERE ParameterId = 1 AND ParameterName = N'@FilePath'
            AND TypeName = N'nvarchar' AND MaxLength = -1
      )
   OR NOT EXISTS
      (
          SELECT 1 FROM @Parameters
          WHERE ParameterId = 2 AND ParameterName = N'@FallbackEncoding'
            AND TypeName = N'nvarchar' AND MaxLength = 256
      )
   OR NOT EXISTS
      (
          SELECT 1 FROM @Parameters
          WHERE ParameterId = 3 AND ParameterName = N'@MaxBytes'
            AND TypeName = N'bigint'
      )
   OR NOT EXISTS
      (
          SELECT 1 FROM @Parameters
          WHERE ParameterId = 4 AND ParameterName = N'@Debug'
            AND TypeName = N'tinyint'
      )
   OR NOT EXISTS
      (
          SELECT 1 FROM @Parameters
          WHERE ParameterId = 5 AND ParameterName = N'@Hilfe'
            AND TypeName = N'bit'
      )
    THROW 52933, N'Die öffentliche LoadTextFile-Signatur ist falsch.', 1;

-- Hilfe-Contract prüfen.
DECLARE @Help TABLE
(
      HelpContractVersion varchar(16)    NOT NULL
    , SchemaName          sysname        NOT NULL
    , ObjectName          sysname        NOT NULL
    , Section             varchar(32)    NOT NULL
    , Ordinal             int            NOT NULL
    , ItemName            sysname        NULL
    , SqlDataType         varchar(256)   NULL
    , IsRequired          bit            NULL
    , IsNullable          bit            NULL
    , DefaultValue        nvarchar(4000) NULL
    , Description         nvarchar(max)  NOT NULL
    , ExampleSql          nvarchar(max)  NULL
);

INSERT INTO @Help
EXEC toolbelt_file.USP_LoadBinaryFile
      @FilePath = N'Darf im Help-Modus nicht gelesen werden.'
    , @Debug = 255
    , @Hilfe = 1;

IF NOT EXISTS
   (
       SELECT 1 FROM @Help
       WHERE Section = N'DESCRIPTION'
         AND ObjectName = N'USP_LoadBinaryFile'
   )
    THROW 52934, N'Der Help-Contract von USP_LoadBinaryFile ist unvollständig.', 1;

DELETE FROM @Help;

INSERT INTO @Help
EXEC toolbelt_file.USP_LoadTextFile
      @FilePath = N'Darf im Help-Modus nicht gelesen werden.'
    , @Debug = 255
    , @Hilfe = 1;

IF NOT EXISTS
   (
       SELECT 1 FROM @Help
       WHERE Section = N'DESCRIPTION'
         AND ObjectName = N'USP_LoadTextFile'
   )
    THROW 52934, N'Der Help-Contract von USP_LoadTextFile ist unvollständig.', 1;

-- Fachliche Validierungsfälle (ohne echtes Dateisystem).
DECLARE @Result TABLE
(
      Content           varbinary(max) NULL
    , BytesRead         bigint         NOT NULL
    , IsValid           bit            NOT NULL
    , ValidationCode    int            NULL
    , ValidationMessage nvarchar(4000) NULL
);

INSERT INTO @Result
EXEC toolbelt_file.USP_LoadBinaryFile @FilePath = NULL;

IF NOT EXISTS
   (
       SELECT 1 FROM @Result
       WHERE IsValid = 0 AND ValidationCode = 51320
   )
    THROW 52935, N'NULL-Pfad-Validierung fehlt oder falsch.', 1;

DELETE FROM @Result;

INSERT INTO @Result
EXEC toolbelt_file.USP_LoadBinaryFile @FilePath = N'relative/path.bin';

IF NOT EXISTS
   (
       SELECT 1 FROM @Result
       WHERE IsValid = 0 AND ValidationCode = 51320
   )
    THROW 52935, N'Relativer Pfad wird nicht als ungültig erkannt.', 1;

DELETE FROM @Result;

INSERT INTO @Result
EXEC toolbelt_file.USP_LoadBinaryFile @FilePath = N'/etc/../etc/passwd';

IF NOT EXISTS
   (
       SELECT 1 FROM @Result
       WHERE IsValid = 0 AND ValidationCode = 51322
   )
    THROW 52935, N'Traversal-Pfad wird nicht erkannt.', 1;

DELETE FROM @Result;

INSERT INTO @Result
EXEC toolbelt_file.USP_LoadBinaryFile @FilePath = N'/unallowed/path.bin';

IF NOT EXISTS
   (
       SELECT 1 FROM @Result
       WHERE IsValid = 0 AND ValidationCode = 51321
   )
    THROW 52935, N'Allowlist-Verletzung wird nicht erkannt.', 1;

-- Echte Dateisystem-Tests (nur in CI mit vorbereiteten Fixtures).
DECLARE @FixtureRoot nvarchar(4000) = N'/workspace/Modules/toolbelt.file.content/Tests/Runtime/fixtures';

DECLARE @BinaryResult TABLE
(
      Content           varbinary(max) NULL
    , BytesRead         bigint         NOT NULL
    , IsValid           bit            NOT NULL
    , ValidationCode    int            NULL
    , ValidationMessage nvarchar(4000) NULL
);

INSERT INTO @BinaryResult
EXEC toolbelt_file.USP_LoadBinaryFile
      @FilePath = @FixtureRoot + N'/sample.bin';

IF NOT EXISTS
   (
       SELECT 1 FROM @BinaryResult
       WHERE IsValid = 1 AND BytesRead = 6
   )
    THROW 52936, N'Binärdatei konnte nicht korrekt gelesen werden.', 1;

DECLARE @TextResult TABLE
(
      Content           nvarchar(max)  NULL
    , BytesRead         bigint         NOT NULL
    , EncodingDetected  nvarchar(128)  NULL
    , BomPresent        bit            NOT NULL
    , IsValid           bit            NOT NULL
    , ValidationCode    int            NULL
    , ValidationMessage nvarchar(4000) NULL
);

INSERT INTO @TextResult
EXEC toolbelt_file.USP_LoadTextFile
      @FilePath = @FixtureRoot + N'/utf8-bom.txt';

IF NOT EXISTS
   (
       SELECT 1 FROM @TextResult
       WHERE IsValid = 1 AND EncodingDetected = N'UTF-8' AND BomPresent = 1
   )
    THROW 52936, N'UTF-8-Datei mit BOM konnte nicht korrekt gelesen werden.', 1;

DELETE FROM @TextResult;

INSERT INTO @TextResult
EXEC toolbelt_file.USP_LoadTextFile
      @FilePath = @FixtureRoot + N'/ansi.txt';

IF NOT EXISTS
   (
       SELECT 1 FROM @TextResult
       WHERE IsValid = 1 AND EncodingDetected = N'Windows-1252' AND BomPresent = 0
   )
    THROW 52936, N'ANSI-Datei ohne BOM konnte nicht korrekt gelesen werden.', 1;

DELETE FROM @TextResult;

INSERT INTO @TextResult
EXEC toolbelt_file.USP_LoadTextFile
      @FilePath = @FixtureRoot + N'/utf16le-bom.txt';

IF NOT EXISTS
   (
       SELECT 1 FROM @TextResult
       WHERE IsValid = 1 AND EncodingDetected = N'UTF-16-LE' AND BomPresent = 1
   )
    THROW 52936, N'UTF-16-LE-Datei mit BOM konnte nicht korrekt gelesen werden.', 1;

PRINT N'File Content Contract-Test: erfolgreich';
