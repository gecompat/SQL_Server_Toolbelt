SET NOCOUNT ON;

DECLARE @CompatibilityLevel int = TRY_CONVERT(int, N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN (150, 160, 170)
    THROW 52930, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID())
       <> @CompatibilityLevel
    THROW 52931, N'Falscher Compatibility Level.', 1;

IF OBJECT_ID(N'toolbelt_core.USP_WriteConsoleMessage', N'P') IS NULL
    THROW 52932, N'USP_WriteConsoleMessage fehlt oder besitzt den falschen Typ.', 1;

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
      OBJECT_ID(N'toolbelt_core.USP_WriteConsoleMessage');

IF (SELECT COUNT(*) FROM @Parameters) <> 4
   OR NOT EXISTS
      (
          SELECT 1 FROM @Parameters
          WHERE ParameterId = 1 AND ParameterName = N'@Message'
            AND TypeName = N'nvarchar' AND MaxLength = -1
      )
   OR NOT EXISTS
      (
          SELECT 1 FROM @Parameters
          WHERE ParameterId = 2 AND ParameterName = N'@Immediate'
            AND TypeName = N'bit'
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
    THROW 52933, N'Die öffentliche Console-Message-Signatur ist falsch.', 1;

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
EXEC toolbelt_core.USP_WriteConsoleMessage
      @Message = N'Darf im Help-Modus nicht ausgegeben werden.'
    , @Immediate = 1
    , @Debug = 255
    , @Hilfe = 1;

IF NOT EXISTS
   (
       SELECT 1 FROM @Help
       WHERE Section = 'DESCRIPTION'
   )
   OR NOT EXISTS
   (
       SELECT 1 FROM @Help
       WHERE Section = 'PARAMETER' AND ItemName = N'@Message'
   )
   OR NOT EXISTS
   (
       SELECT 1 FROM @Help
       WHERE Section = 'RESULT_COLUMN'
         AND ItemName IS NULL
         AND SqlDataType IS NULL
   )
   OR NOT EXISTS
   (
       SELECT 1 FROM @Help
       WHERE Section = 'EXAMPLE'
   )
    THROW 52934, N'Der Console-Message-Help-Vertrag ist unvollständig.', 1;

DECLARE @ReturnCode int;
EXEC @ReturnCode = toolbelt_core.USP_WriteConsoleMessage
      @Message = NULL
    , @Immediate = NULL
    , @Debug = NULL
    , @Hilfe = NULL;
IF @ReturnCode <> 0
    THROW 52935, N'Der NULL-Vertrag liefert einen falschen Return Code.', 1;

EXEC @ReturnCode = toolbelt_core.USP_WriteConsoleMessage
      @Message = N''
    , @Immediate = 1;
IF @ReturnCode <> 0
    THROW 52936, N'Der Leertext-Vertrag liefert einen falschen Return Code.', 1;

DECLARE @LongBuffered nvarchar(max) =
      CONVERT(nvarchar(max), N'BUFFERED|')
    + REPLICATE(CONVERT(nvarchar(max), N'α'), 8500)
    + N'|END';
DECLARE @LongImmediate nvarchar(max) =
      CONVERT(nvarchar(max), N'IMMEDIATE|100 %|')
    + REPLICATE(CONVERT(nvarchar(max), N'β'), 4500)
    + N'|END';

EXEC @ReturnCode = toolbelt_core.USP_WriteConsoleMessage
      @Message = @LongBuffered
    , @Immediate = 0;
IF @ReturnCode <> 0
    THROW 52937, N'Der PRINT-Provider liefert einen falschen Return Code.', 1;

EXEC @ReturnCode = toolbelt_core.USP_WriteConsoleMessage
      @Message = @LongImmediate
    , @Immediate = 1;
IF @ReturnCode <> 0
    THROW 52938, N'Der NOWAIT-Provider liefert einen falschen Return Code.', 1;

PRINT N'Console Message Contract-Prüfung: erfolgreich';
GO
