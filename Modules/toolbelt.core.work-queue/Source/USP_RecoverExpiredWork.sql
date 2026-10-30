SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_RecoverExpiredWork]
(
      @MaxItems    int     = 100
    , @ResultTable sysname = NULL
    , @KeepData    bit     = 0
    , @Debug       tinyint = 0
    , @Hilfe       bit     = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;
    SET @KeepData=ISNULL(@KeepData,0); SET @Debug=ISNULL(@Debug,0); SET @Hilfe=ISNULL(@Hilfe,0);
    IF @Hilfe=1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_RecoverExpiredWork' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Plant für abgelaufene Claims nach der gespeicherten Retry-Policy RETRY_WAIT oder DEAD_LETTER. Alte ClaimTokens werden atomar invalidiert.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'WorkItemId', N'bigint', 0, 0, NULL, CAST(N'Eindeutige Queue-ID.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'WorkTypeName', N'varchar(128)', 0, 0, NULL, CAST(N'Kanonischer Work-Type-Name.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'Status', N'varchar(16)', 0, 0, NULL, CAST(N'RETRY_WAIT oder DEAD_LETTER nach gespeicherter Policy.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'ClaimGeneration', N'bigint', 0, 0, NULL, CAST(N'Letzte invalidierte Ownership-Generation.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'RecoveryCount', N'bigint', 0, 0, NULL, CAST(N'Kumulierte Zahl kontrollierter Recoveries.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'LastRecoveredAtUtc', N'datetime2(7)', 0, 0, NULL, CAST(N'Engine-Zeit der Recovery.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'LastRecoveredBy', N'sysname', 0, 0, NULL, CAST(N'Original-Login der Recovery.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51960-51964', NULL, NULL, NULL, NULL, CAST(N'Caller-Transaktions-, Batch- oder ResultTable-Fehler.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Recovert höchstens 100 abgelaufene Claims.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_RecoverExpiredWork @MaxItems=100;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@MaxItems', N'int', 0, 0, N'100', CAST(N'Ganzzahl 1..1000 als Batchobergrenze einschließlich, Default 100; NULL/0/negativ/>1000 wird abgewiesen. Es werden nur abgelaufene Claims bis zu dieser Anzahl bearbeitet; keine Callertransaktion erlaubt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51960,N'USP_RecoverExpiredWork darf nicht innerhalb einer Caller-Transaktion ausgeführt werden.',1;
    IF @MaxItems IS NULL OR @MaxItems NOT BETWEEN 1 AND 1000 THROW 51961,N'@MaxItems muss zwischen 1 und 1000 liegen.',1;

    CREATE TABLE #tbx_WorkQueue_RecoveryShape(WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,ClaimGeneration bigint NOT NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NOT NULL,LastRecoveredBy sysname NOT NULL);
    CREATE TABLE #tbx_WorkQueue_RecoveryResult(WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,ClaimGeneration bigint NOT NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NOT NULL,LastRecoveredBy sysname NOT NULL);
    DECLARE @Recovered TABLE(WorkItemId bigint NOT NULL PRIMARY KEY);
    DECLARE @NowUtc datetime2(7)=SYSUTCDATETIME(),@RecoveredBy sysname=ORIGINAL_LOGIN();
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @ResultTable IS NOT NULL
        BEGIN
            IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL THROW 51964,N'Für @ResultTable fehlt toolbelt.core.result-table.',1;
            EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_WorkQueue_RecoveryShape',@KeepData=@KeepData;
        END;
        ;WITH Expired AS
        (
            SELECT TOP (@MaxItems) * FROM toolbelt_core.WorkItem WITH(UPDLOCK,READPAST,READCOMMITTEDLOCK,ROWLOCK,INDEX(IX_WorkItem_Status_LeaseUntilUtc_WorkItemId))
            WHERE Status='CLAIMED' AND LeaseUntilUtc<=@NowUtc AND ManagedReservationId IS NULL AND ManagedHold=0
            ORDER BY LeaseUntilUtc,WorkItemId
        )
        UPDATE Expired SET
              Status=CASE WHEN CycleAttemptCount>=MaxAttempts THEN 'DEAD_LETTER' ELSE 'RETRY_WAIT' END,ClaimedAtUtc=NULL,ClaimedBy=NULL,ClaimToken=NULL
            , LeaseDurationSeconds=NULL,LeaseUntilUtc=NULL,LastHeartbeatAtUtc=NULL
            , RecoveryCount=RecoveryCount+1,LastRecoveredAtUtc=@NowUtc,LastRecoveredBy=@RecoveredBy
            , NextAttemptAtUtc=CASE WHEN CycleAttemptCount>=MaxAttempts THEN NULL ELSE DATEADD(SECOND,CASE WHEN CycleAttemptCount>=31 OR RetryBaseDelaySeconds*POWER(CONVERT(float,2),CycleAttemptCount-1)>RetryMaxDelaySeconds THEN RetryMaxDelaySeconds ELSE CONVERT(int,RetryBaseDelaySeconds*POWER(CONVERT(float,2),CycleAttemptCount-1)) END,@NowUtc) END
            , DeadLetteredAtUtc=CASE WHEN CycleAttemptCount>=MaxAttempts THEN @NowUtc ELSE DeadLetteredAtUtc END
            , DeadLetteredBy=CASE WHEN CycleAttemptCount>=MaxAttempts THEN @RecoveredBy ELSE DeadLetteredBy END
        OUTPUT inserted.WorkItemId INTO @Recovered(WorkItemId);

        INSERT INTO #tbx_WorkQueue_RecoveryResult
        SELECT wi.WorkItemId,wt.WorkTypeName,wi.Status,wi.ClaimGeneration,wi.RecoveryCount,wi.LastRecoveredAtUtc,wi.LastRecoveredBy
        FROM @Recovered r JOIN toolbelt_core.WorkItem wi ON wi.WorkItemId=r.WorkItemId
        JOIN toolbelt_core.WorkType wt ON wt.WorkTypeId=wi.WorkTypeId;
        IF @ResultTable IS NOT NULL
        BEGIN
            DECLARE @InsertSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N' (WorkItemId,WorkTypeName,Status,ClaimGeneration,RecoveryCount,LastRecoveredAtUtc,LastRecoveredBy) SELECT WorkItemId,WorkTypeName,Status,ClaimGeneration,RecoveryCount,LastRecoveredAtUtc,LastRecoveredBy FROM #tbx_WorkQueue_RecoveryResult;';
            EXEC sys.sp_executesql @InsertSql;
        END;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    IF @Debug>0 RAISERROR(N'USP_RecoverExpiredWork: abgelaufene Claims kontrolliert zurückgesetzt.',10,1) WITH NOWAIT;
    IF @ResultTable IS NULL SELECT * FROM #tbx_WorkQueue_RecoveryResult ORDER BY LastRecoveredAtUtc,WorkItemId;
    RETURN 0;
END;
GO
