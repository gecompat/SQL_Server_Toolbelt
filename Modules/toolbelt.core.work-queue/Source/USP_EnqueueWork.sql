SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_EnqueueWork]
(
      @WorkTypeName varchar(128)  = NULL
    , @PayloadJson  nvarchar(max) = NULL
    , @ResultTable  sysname       = NULL
    , @KeepData     bit           = 0
    , @Debug        tinyint       = 0
    , @Hilfe        bit           = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;

    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_EnqueueWork' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'WorkItemId', N'bigint', 0, 0, NULL, CAST(N'Eindeutige Queue-ID.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'WorkTypeName', N'varchar(128)', 0, 0, NULL, CAST(N'Kanonischer Work-Type-Name.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'Status', N'varchar(16)', 0, 0, NULL, CAST(N'Nach Enqueue stets QUEUED.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'EnqueuedAtUtc', N'datetime2(7)', 0, 0, NULL, CAST(N'UTC-Zeitpunkt der Einreihung.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'EnqueuedBy', N'sysname', 0, 0, NULL, CAST(N'Original-Login der Einreihung.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'ClaimedAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'UTC-Zeitpunkt des Claims; nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'ClaimedBy', N'sysname', 0, 1, NULL, CAST(N'Original-Login des Claimers; nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 8, N'CompletedAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'UTC-Abschlusszeit; nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 9, N'CompletedBy', N'sysname', 0, 1, NULL, CAST(N'Original-Login des Abschlusses; nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 10, N'FailedAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'UTC-Fehlerzeit; nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 11, N'FailedBy', N'sysname', 0, 1, NULL, CAST(N'Original-Login des Fail-Aufrufs; nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 12, N'FailureCode', N'varchar(64)', 0, 1, NULL, CAST(N'Stabiler Fehlercode; nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 13, N'FailureMessage', N'nvarchar(1000)', 0, 1, NULL, CAST(N'Optionale bereinigte Fehlermeldung; nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 14, N'RowVersion', N'binary(8)', 0, 0, NULL, CAST(N'Aktueller Concurrency-Marker.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 15, N'ClaimGeneration', N'bigint', 0, 0, NULL, CAST(N'Nach Enqueue 0; wird bei jedem Claim erhöht.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 16, N'LeaseDurationSeconds', N'int', 0, 1, NULL, CAST(N'Nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 17, N'LeaseUntilUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'Nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 18, N'LastHeartbeatAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'Nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 19, N'IsLeaseExpired', N'bit', 0, 0, NULL, CAST(N'Nach Enqueue 0.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 20, N'RecoveryCount', N'bigint', 0, 0, NULL, CAST(N'Nach Enqueue 0.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 21, N'LastRecoveredAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'Nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 22, N'LastRecoveredBy', N'sysname', 0, 1, NULL, CAST(N'Nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51900-51908,51998', NULL, NULL, NULL, NULL, CAST(N'Work-Type-, Payload-, Transaktions- oder ResultTable-Fehler. 51998: explizites ENQUEUE fehlt oder DENY gewinnt; Prüfung vor Insert und Idempotencyauskunft.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Reiht synthetische JSON-Arbeit ein.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName=''demo.json'', @PayloadJson=N''{"value":1}'';' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@WorkTypeName', N'varchar(128)', 1, 0, N'NULL', CAST(N'Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Erfordert aktiven Eintrag und ENQUEUE-Policy; dieser ältere Enqueue-Pfad benötigt zusätzlich Metadatensicht auf den Handler.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@PayloadJson', N'nvarchar(max)', 0, 1, N'NULL', CAST(N'Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N''{"value":1}''. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    IF NULLIF(@WorkTypeName, '') IS NULL
        THROW 51900, N'@WorkTypeName ist erforderlich.', 1;
    IF DATALENGTH(@PayloadJson) > 65536
        THROW 51905, N'@PayloadJson darf höchstens 64 KiB umfassen.', 1;
    IF XACT_STATE() = -1
        THROW 51906, N'Ein Work Item kann in einer uncommittable Caller-Transaktion nicht eingereiht werden.', 1;

    CREATE TABLE #tbx_WorkQueue_StatusShape
    (
          WorkItemId bigint NOT NULL
        , WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL
        , EnqueuedAtUtc datetime2(7) NOT NULL
        , EnqueuedBy sysname NOT NULL
        , ClaimedAtUtc datetime2(7) NULL
        , ClaimedBy sysname NULL
        , CompletedAtUtc datetime2(7) NULL
        , CompletedBy sysname NULL
        , FailedAtUtc datetime2(7) NULL
        , FailedBy sysname NULL
        , FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL
        , FailureMessage nvarchar(1000) NULL
        , RowVersion binary(8) NOT NULL
        , ClaimGeneration bigint NOT NULL
        , LeaseDurationSeconds int NULL
        , LeaseUntilUtc datetime2(7) NULL
        , LastHeartbeatAtUtc datetime2(7) NULL
        , IsLeaseExpired bit NOT NULL
        , RecoveryCount bigint NOT NULL
        , LastRecoveredAtUtc datetime2(7) NULL
        , LastRecoveredBy sysname NULL
    );
    CREATE TABLE #tbx_WorkQueue_StatusResult
    (
          WorkItemId bigint NOT NULL
        , WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL
        , EnqueuedAtUtc datetime2(7) NOT NULL
        , EnqueuedBy sysname NOT NULL
        , ClaimedAtUtc datetime2(7) NULL
        , ClaimedBy sysname NULL
        , CompletedAtUtc datetime2(7) NULL
        , CompletedBy sysname NULL
        , FailedAtUtc datetime2(7) NULL
        , FailedBy sysname NULL
        , FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL
        , FailureMessage nvarchar(1000) NULL
        , RowVersion binary(8) NOT NULL
        , ClaimGeneration bigint NOT NULL
        , LeaseDurationSeconds int NULL
        , LeaseUntilUtc datetime2(7) NULL
        , LastHeartbeatAtUtc datetime2(7) NULL
        , IsLeaseExpired bit NOT NULL
        , RecoveryCount bigint NOT NULL
        , LastRecoveredAtUtc datetime2(7) NULL
        , LastRecoveredBy sysname NULL
    );

    DECLARE @InitialTranCount int = @@TRANCOUNT;
    DECLARE @WorkTypeId bigint;
    DECLARE @ParameterMode varchar(16);
    DECLARE @IsEnabled bit;
    DECLARE @HandlerSchema sysname;
    DECLARE @HandlerProcedure sysname;
    DECLARE @WorkItemId bigint;

    IF @InitialTranCount = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION TBX_WorkQueue_Enqueue;

    BEGIN TRY
        SELECT
              @WorkTypeId = wt.WorkTypeId
            , @ParameterMode = wt.ParameterMode
            , @IsEnabled = wt.IsEnabled
            , @HandlerSchema = wt.HandlerSchema
            , @HandlerProcedure = wt.HandlerProcedure
        FROM toolbelt_core.WorkType AS wt WITH (UPDLOCK, HOLDLOCK)
        WHERE wt.WorkTypeName = @WorkTypeName;

        IF @WorkTypeId IS NULL
            THROW 51900, N'Der angeforderte Work Type ist nicht registriert.', 1;
        IF @IsEnabled <> 1
            THROW 51901, N'Der angeforderte Work Type ist deaktiviert.', 1;
        IF COALESCE
           (
               OBJECT_ID(QUOTENAME(@HandlerSchema) + N'.' + QUOTENAME(@HandlerProcedure), N'P'),
               OBJECT_ID(QUOTENAME(@HandlerSchema) + N'.' + QUOTENAME(@HandlerProcedure), N'PC')
           ) IS NULL
            THROW 51902, N'Der registrierte Work-Type-Handler ist nicht verfügbar.', 1;
        IF NOT EXISTS(SELECT 1 FROM toolbelt_core.TVF_WorkTypeAuthorization(@WorkTypeId,'ENQUEUE') WHERE IsAllowed=1)
            THROW 51998,N'Keine Einreihberechtigung für diesen Work Type.',1;
        IF @ParameterMode = 'NONE' AND @PayloadJson IS NOT NULL
            THROW 51903, N'Für einen Work Type mit ParameterMode NONE muss @PayloadJson NULL sein.', 1;
        IF @ParameterMode = 'JSON_PAYLOAD'
           AND (@PayloadJson IS NULL OR ISJSON(@PayloadJson) <> 1 OR LEFT(LTRIM(@PayloadJson), 1) <> N'{')
            THROW 51904, N'Für JSON_PAYLOAD muss @PayloadJson ein JSON-Objekt sein.', 1;

        IF @ResultTable IS NOT NULL
        BEGIN
            IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
                THROW 51908, N'Für @ResultTable fehlt toolbelt.core.result-table.', 1;
            EXEC toolbelt_core.USP_PrepareResultTable
                  @ResultTableToAlter = @ResultTable
                , @LikeTable = N'#tbx_WorkQueue_StatusShape'
                , @KeepData = @KeepData;
        END;

        INSERT INTO toolbelt_core.WorkItem (WorkTypeId, PayloadJson)
        VALUES (@WorkTypeId, @PayloadJson);
        SET @WorkItemId = SCOPE_IDENTITY();

        INSERT INTO #tbx_WorkQueue_StatusResult
        SELECT WorkItemId,WorkTypeName,Status,EnqueuedAtUtc,EnqueuedBy,ClaimedAtUtc,ClaimedBy,CompletedAtUtc,CompletedBy,FailedAtUtc,FailedBy,FailureCode,FailureMessage,RowVersion,ClaimGeneration,LeaseDurationSeconds,LeaseUntilUtc,LastHeartbeatAtUtc,IsLeaseExpired,RecoveryCount,LastRecoveredAtUtc,LastRecoveredBy
        FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId = @WorkItemId;

        IF @ResultTable IS NOT NULL
        BEGIN
            DECLARE @InsertSql nvarchar(max) =
                N'INSERT INTO ' + QUOTENAME(@ResultTable)
                + N' (WorkItemId, WorkTypeName, Status, EnqueuedAtUtc, EnqueuedBy, ClaimedAtUtc, ClaimedBy, CompletedAtUtc, CompletedBy, FailedAtUtc, FailedBy, FailureCode, FailureMessage, RowVersion, ClaimGeneration, LeaseDurationSeconds, LeaseUntilUtc, LastHeartbeatAtUtc, IsLeaseExpired, RecoveryCount, LastRecoveredAtUtc, LastRecoveredBy)'
                + N' SELECT WorkItemId, WorkTypeName, Status, EnqueuedAtUtc, EnqueuedBy, ClaimedAtUtc, ClaimedBy, CompletedAtUtc, CompletedBy, FailedAtUtc, FailedBy, FailureCode, FailureMessage, RowVersion, ClaimGeneration, LeaseDurationSeconds, LeaseUntilUtc, LastHeartbeatAtUtc, IsLeaseExpired, RecoveryCount, LastRecoveredAtUtc, LastRecoveredBy FROM #tbx_WorkQueue_StatusResult;';
            EXEC sys.sp_executesql @InsertSql;
        END;

        IF @InitialTranCount = 0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @InitialTranCount = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @InitialTranCount > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION TBX_WorkQueue_Enqueue;
        THROW;
    END CATCH;

    IF @Debug > 0
        RAISERROR(N'USP_EnqueueWork: ein Work Item wurde eingereiht.', 10, 1) WITH NOWAIT;
    IF @ResultTable IS NULL SELECT * FROM #tbx_WorkQueue_StatusResult;
    RETURN 0;
END;
GO
