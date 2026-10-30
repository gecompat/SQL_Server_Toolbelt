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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_CaptureErrorEnvelope' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Erzeugt aus explizit im aufrufenden CATCH gelesenen ERROR_*-Werten genau eine standardisierte Fehlerzeile. Die Procedure führt keinen Rethrow aus; der Aufrufer verwendet anschließend THROW; im ursprünglichen CATCH.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'CapturedAtUtc', N'datetime2(7)', 0, 0, NULL, CAST(N'UTC-Zeitpunkt der Erfassung.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'ExecutionId', N'uniqueidentifier', 0, 1, NULL, CAST(N'Explizite oder aus SESSION_CONTEXT gelesene Execution-ID.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'ErrorClass', N'varchar(16)', 0, 0, NULL, CAST(N'ENGINE, TOOLBELT oder USER.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51400-51405', NULL, NULL, NULL, NULL, CAST(N'Validierungs- und Dependencyfehler des Moduls.' AS nvarchar(max)), NULL),
        (N'ERROR', 2, N'51406', NULL, NULL, NULL, NULL, CAST(N'ResultTable-Ausgabe bei XACT_STATE()=-1 wird vor jeder Schreiboperation abgewiesen. Direkte Ausgabe bleibt lesend möglich.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Aufruf innerhalb eines CATCH mit anschließendem unverändertem THROW.' AS nvarchar(max)), CAST(N'BEGIN CATCH EXEC toolbelt_core.USP_CaptureErrorEnvelope @ErrorNumber=ERROR_NUMBER(), @ErrorSeverity=ERROR_SEVERITY(), @ErrorState=ERROR_STATE(), @ErrorProcedure=ERROR_PROCEDURE(), @ErrorLine=ERROR_LINE(), @ErrorMessage=ERROR_MESSAGE(); THROW; END CATCH;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@ErrorNumber', N'int', 1, 0, N'NULL', CAST(N'Fachlich erforderlich: positive int-Fehlernummer 1..2147483647, üblicherweise ERROR_NUMBER() im aufrufenden CATCH. Technischer Default NULL dient nur Help; NULL/<=0 wird 51400.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@ErrorSeverity', N'int', 1, 0, N'NULL', CAST(N'Fachlich erforderlich: int 0..25 einschließlich, üblicherweise ERROR_SEVERITY() aus demselben CATCH. NULL/außerhalb ergibt 51401; technischer Default NULL nur für Help.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ErrorState', N'int', 1, 0, N'NULL', CAST(N'Fachlich erforderlich: int 0..255 einschließlich aus ERROR_STATE() im CATCH. NULL/außerhalb ergibt 51402; technischer Default NULL nur für Help.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@ErrorProcedure', N'nvarchar(776)', 0, 1, N'NULL', CAST(N'Optionaler reiner Unicode-Text nvarchar(776), normalerweise ERROR_PROCEDURE() im CATCH, kein auszuführender Objektname. NULL bleibt NULL, leerer Text wird nicht besonders validiert.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@ErrorLine', N'int', 0, 1, N'NULL', CAST(N'Optionale positive int-Zeilennummer aus ERROR_LINE(); NULL (Default) ist erlaubt, 0/negativ ergibt 51403.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@ErrorMessage', N'nvarchar(4000)', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher Unicode-Fehlertext nvarchar(4000), normalerweise ERROR_MESSAGE() im CATCH. NULL, leer und nach SQL-Gleichheit leere reine Spacefolgen ergeben 51404; keine automatische Redigierung geheimer Inhalte.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@ExecutionId', N'uniqueidentifier', 0, 1, N'NULL', CAST(N'Optionaler SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier). Default/NULL liest toolbelt.execution.id aus SESSION_CONTEXT mit TRY_CONVERT; fehlender/ungültiger Kontext bleibt NULL. Eine explizite ID muss keinem gespeicherten Kontext entsprechen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@AdditionalContext', N'nvarchar(4000)', 0, 1, N'NULL', CAST(N'Optionaler Unicode-Freitext nvarchar(4000), kein vorgeschriebenes JSON-Schema und keine Ausführung. NULL/leer wird unverändert ausgegeben; nur bereits bereinigte, für den Empfänger zulässige Zusatzinformation übergeben.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) gibt eine direkte Fehlerzeile aus, auch bei XACT_STATE()=-1. Sonst Name einer bereits vom Caller angelegten lokalen #Temp-Tabelle als sysname, z.B. N''#Envelope'', keine globale oder mehrteilige Tabelle; ResultTable-Helper nötig. Bei uncommittable Caller zuerst Rollback, sonst 51406.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 bereitet Replace vor (Default), 1 hängt bei kompatibler ResultTable an; NULL wird vom kanonischen Helper wie 0 behandelt. Nur bei nicht-NULL ResultTable relevant.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) und NULL ohne Diagnose; 1..255 erzeugen eine abstrakte Informationsmeldung ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur Hilfe vor Fachvalidierung; 0 (Default) und NULL führen die Fachoperation aus. Im Hilfemodus sind die fachlich erforderlichen Error*-Werte nicht nötig.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
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

    -- Ein doomed Caller darf für die direkte Fehlerausgabe weder Temp-DDL
    -- noch INSERT ausführen. Typen/Nullability entsprechen dem bisherigen Schema.
    IF @ResultTable IS NULL
    BEGIN
        IF @Debug > 0
            RAISERROR(N'USP_CaptureErrorEnvelope: eine standardisierte Fehlerzeile wurde erzeugt.', 10, 1) WITH NOWAIT;
        SELECT ISNULL(CONVERT(datetime2(7),SYSUTCDATETIME()),CONVERT(datetime2(7),'20000101')) AS CapturedAtUtc,
            @ExecutionId AS ExecutionId,
            ISNULL(CONVERT(varchar(16),CASE WHEN @ErrorNumber BETWEEN 51000 AND 51999 THEN 'TOOLBELT' WHEN @ErrorNumber<50000 THEN 'ENGINE' ELSE 'USER' END),'USER') AS ErrorClass,
            ISNULL(@ErrorNumber,0) AS ErrorNumber, ISNULL(@ErrorSeverity,0) AS ErrorSeverity,
            ISNULL(@ErrorState,0) AS ErrorState, @ErrorProcedure AS ErrorProcedure,
            @ErrorLine AS ErrorLine, ISNULL(@ErrorMessage,N'') AS ErrorMessage,
            ISNULL(CONVERT(smallint,XACT_STATE()),CONVERT(smallint,0)) AS XactState, ISNULL(@@TRANCOUNT,0) AS TransactionCount,
            ISNULL(DB_NAME(),CONVERT(sysname,N'')) AS DatabaseName, ISNULL(CONVERT(int,@@SPID),0) AS SessionId,
            @AdditionalContext AS AdditionalContext;
        RETURN 0;
    END;
    IF XACT_STATE()=-1
        THROW 51406,N'ResultTable-Ausgabe erfordert zuerst den Rollback des uncommittable Callers.',1;

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
