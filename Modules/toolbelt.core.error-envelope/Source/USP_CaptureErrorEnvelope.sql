-- ============================================================================
-- Objekt: toolbelt_core.USP_CaptureErrorEnvelope
-- Zweck: Standardisiert explizit aus einem CATCH übergebene Fehlerdaten.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_CaptureErrorEnvelope]
(
      @ErrorNumber       int             = NULL
    , @ErrorSeverity     int             = NULL
    , @ErrorState        int             = NULL
    , @ErrorProcedure    nvarchar(776)   = NULL
    , @ErrorLine         int             = NULL
    , @ErrorMessage      nvarchar(4000)  = NULL
    , @ExecutionId       uniqueidentifier = NULL
    , @AdditionalContext nvarchar(4000)  = NULL
    , @ResultTable       sysname         = NULL
    , @KeepData          bit             = 0
    , @Debug             tinyint         = 0
    , @Hilfe             bit             = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT
              CAST('1.0' AS varchar(16)) AS HelpContractVersion
            , CAST(N'toolbelt_core' AS sysname) AS SchemaName
            , CAST(N'USP_CaptureErrorEnvelope' AS sysname) AS ObjectName
            , v.Section
            , v.Ordinal
            , v.ItemName
            , v.SqlDataType
            , v.IsRequired
            , v.IsNullable
            , v.DefaultValue
            , v.Description
            , v.ExampleSql
        FROM
        (
            VALUES
              (CAST('DESCRIPTION' AS varchar(32)), 1, CAST(NULL AS sysname), CAST(NULL AS varchar(256)), CAST(NULL AS bit), CAST(NULL AS bit), CAST(NULL AS nvarchar(4000)), CAST(N'Erzeugt aus explizit im aufrufenden CATCH gelesenen ERROR_*-Werten genau eine standardisierte Fehlerzeile. Die Procedure führt keinen Rethrow aus; der Aufrufer verwendet anschließend THROW; im ursprünglichen CATCH.' AS nvarchar(max)), CAST(NULL AS nvarchar(max)))
            , ('PARAMETER', 1, N'@ErrorNumber', 'int', 1, 0, NULL, N'ERROR_NUMBER() aus dem aufrufenden CATCH.', NULL)
            , ('PARAMETER', 2, N'@ErrorSeverity', 'int', 1, 0, NULL, N'ERROR_SEVERITY() aus dem aufrufenden CATCH.', NULL)
            , ('PARAMETER', 3, N'@ErrorState', 'int', 1, 0, NULL, N'ERROR_STATE() aus dem aufrufenden CATCH.', NULL)
            , ('PARAMETER', 4, N'@ErrorProcedure', 'nvarchar(776)', 0, 1, NULL, N'ERROR_PROCEDURE() aus dem aufrufenden CATCH.', NULL)
            , ('PARAMETER', 5, N'@ErrorLine', 'int', 0, 1, NULL, N'ERROR_LINE() aus dem aufrufenden CATCH.', NULL)
            , ('PARAMETER', 6, N'@ErrorMessage', 'nvarchar(4000)', 1, 0, NULL, N'ERROR_MESSAGE() aus dem aufrufenden CATCH.', NULL)
            , ('PARAMETER', 7, N'@ExecutionId', 'uniqueidentifier', 0, 1, NULL, N'Optionale Execution-ID; NULL liest den aktiven Toolbelt Execution Context.', NULL)
            , ('PARAMETER', 8, N'@AdditionalContext', 'nvarchar(4000)', 0, 1, NULL, N'Optionale synthetische oder bereits bereinigte Zusatzinformation.', NULL)
            , ('PARAMETER', 9, N'@ResultTable', 'sysname', 0, 1, NULL, N'Optionale lokale Temp-Tabelle für das Ergebnis.', NULL)
            , ('PARAMETER', 10, N'@KeepData', 'bit', 0, 1, N'0', N'Steuert die ResultTable-Vorbereitung.', NULL)
            , ('PARAMETER', 11, N'@Debug', 'tinyint', 0, 1, N'0', N'Erzeugt bei Werten größer 0 eine abstrakte Informationsmeldung.', NULL)
            , ('PARAMETER', 12, N'@Hilfe', 'bit', 0, 1, N'0', N'1 gibt ausschließlich dieses Help-Resultset aus.', NULL)
            , ('RESULT_COLUMN', 1, N'CapturedAtUtc', 'datetime2(7)', 0, 0, NULL, N'UTC-Zeitpunkt der Erfassung.', NULL)
            , ('RESULT_COLUMN', 2, N'ExecutionId', 'uniqueidentifier', 0, 1, NULL, N'Explizite oder aus SESSION_CONTEXT gelesene Execution-ID.', NULL)
            , ('RESULT_COLUMN', 3, N'ErrorClass', 'varchar(16)', 0, 0, NULL, N'ENGINE, TOOLBELT oder USER.', NULL)
            , ('ERROR', 1, N'51400-51405', NULL, NULL, NULL, NULL, N'Validierungs- und Dependencyfehler des Moduls.', NULL)
            , ('EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, N'Aufruf innerhalb eines CATCH mit anschließendem unverändertem THROW.', N'BEGIN CATCH EXEC toolbelt_core.USP_CaptureErrorEnvelope @ErrorNumber=ERROR_NUMBER(), @ErrorSeverity=ERROR_SEVERITY(), @ErrorState=ERROR_STATE(), @ErrorProcedure=ERROR_PROCEDURE(), @ErrorLine=ERROR_LINE(), @ErrorMessage=ERROR_MESSAGE(); THROW; END CATCH;')
        ) AS v(Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue, Description, ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 ELSE 5 END, v.Ordinal;
        RETURN 0;
    END;

    IF @ErrorNumber IS NULL OR @ErrorNumber <= 0
        THROW 51400, N'@ErrorNumber muss eine positive Fehlernummer enthalten.', 1;
    IF @ErrorSeverity IS NULL OR @ErrorSeverity NOT BETWEEN 0 AND 25
        THROW 51401, N'@ErrorSeverity muss zwischen 0 und 25 liegen.', 1;
    IF @ErrorState IS NULL OR @ErrorState NOT BETWEEN 0 AND 255
        THROW 51402, N'@ErrorState muss zwischen 0 und 255 liegen.', 1;
    IF @ErrorLine IS NOT NULL AND @ErrorLine <= 0
        THROW 51403, N'@ErrorLine muss NULL oder positiv sein.', 1;
    IF NULLIF(@ErrorMessage, N'') IS NULL
        THROW 51404, N'@ErrorMessage darf nicht leer sein.', 1;

    IF @ExecutionId IS NULL
        SET @ExecutionId = TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id'));

    CREATE TABLE #tbx_ErrorEnvelopeShape
    (
          CapturedAtUtc    datetime2(7)    NOT NULL
        , ExecutionId      uniqueidentifier NULL
        , ErrorClass       varchar(16)     NOT NULL
        , ErrorNumber      int             NOT NULL
        , ErrorSeverity    int             NOT NULL
        , ErrorState       int             NOT NULL
        , ErrorProcedure   nvarchar(776)   NULL
        , ErrorLine        int             NULL
        , ErrorMessage     nvarchar(4000)  NOT NULL
        , XactState        smallint        NOT NULL
        , TransactionCount int             NOT NULL
        , DatabaseName     sysname         NOT NULL
        , SessionId        int             NOT NULL
        , AdditionalContext nvarchar(4000) NULL
    );

    CREATE TABLE #tbx_ErrorEnvelopeResult
    (
          CapturedAtUtc    datetime2(7)    NOT NULL
        , ExecutionId      uniqueidentifier NULL
        , ErrorClass       varchar(16)     NOT NULL
        , ErrorNumber      int             NOT NULL
        , ErrorSeverity    int             NOT NULL
        , ErrorState       int             NOT NULL
        , ErrorProcedure   nvarchar(776)   NULL
        , ErrorLine        int             NULL
        , ErrorMessage     nvarchar(4000)  NOT NULL
        , XactState        smallint        NOT NULL
        , TransactionCount int             NOT NULL
        , DatabaseName     sysname         NOT NULL
        , SessionId        int             NOT NULL
        , AdditionalContext nvarchar(4000) NULL
    );

    INSERT INTO #tbx_ErrorEnvelopeResult
    (
          CapturedAtUtc, ExecutionId, ErrorClass, ErrorNumber, ErrorSeverity
        , ErrorState, ErrorProcedure, ErrorLine, ErrorMessage, XactState
        , TransactionCount, DatabaseName, SessionId, AdditionalContext
    )
    VALUES
    (
          SYSUTCDATETIME()
        , @ExecutionId
        , CASE WHEN @ErrorNumber BETWEEN 51000 AND 51999 THEN 'TOOLBELT'
               WHEN @ErrorNumber < 50000 THEN 'ENGINE'
               ELSE 'USER' END
        , @ErrorNumber, @ErrorSeverity, @ErrorState, @ErrorProcedure
        , @ErrorLine, @ErrorMessage, CONVERT(smallint, XACT_STATE())
        , @@TRANCOUNT, DB_NAME(), @@SPID, @AdditionalContext
    );

    IF @Debug > 0
        RAISERROR(N'USP_CaptureErrorEnvelope: eine standardisierte Fehlerzeile wurde erzeugt.', 10, 1) WITH NOWAIT;

    IF @ResultTable IS NULL
    BEGIN
        SELECT * FROM #tbx_ErrorEnvelopeResult;
        RETURN 0;
    END;

    IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
        THROW 51405, N'Für @ResultTable fehlt toolbelt.core.result-table.', 1;

    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = @ResultTable
        , @LikeTable = N'#tbx_ErrorEnvelopeShape'
        , @KeepData = @KeepData;

    DECLARE @InsertSql nvarchar(max) =
        N'INSERT INTO ' + QUOTENAME(@ResultTable)
        + N' (CapturedAtUtc, ExecutionId, ErrorClass, ErrorNumber, ErrorSeverity, ErrorState, ErrorProcedure, ErrorLine, ErrorMessage, XactState, TransactionCount, DatabaseName, SessionId, AdditionalContext)'
        + N' SELECT CapturedAtUtc, ExecutionId, ErrorClass, ErrorNumber, ErrorSeverity, ErrorState, ErrorProcedure, ErrorLine, ErrorMessage, XactState, TransactionCount, DatabaseName, SessionId, AdditionalContext FROM #tbx_ErrorEnvelopeResult;';
    EXEC sys.sp_executesql @InsertSql;
    RETURN 0;
END;
GO
