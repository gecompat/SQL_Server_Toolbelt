SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_GetWorkStatus]
(
      @WorkItemId bigint   = NULL
    , @ResultTable sysname = NULL
    , @KeepData    bit     = 0
    , @Debug       tinyint = 0
    , @Hilfe       bit     = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @KeepData=ISNULL(@KeepData,0); SET @Debug=ISNULL(@Debug,0); SET @Hilfe=ISNULL(@Hilfe,0);
    IF @Hilfe=1
    BEGIN
        SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_GetWorkStatus' AS sysname) ObjectName,
               v.Section,v.Ordinal,v.ItemName,v.SqlDataType,v.IsRequired,v.IsNullable,v.DefaultValue,v.Description,v.ExampleSql
        FROM (VALUES
          (CAST('DESCRIPTION' AS varchar(32)),1,CAST(NULL AS sysname),CAST(NULL AS varchar(256)),CAST(NULL AS bit),CAST(NULL AS bit),CAST(NULL AS nvarchar(4000)),CAST(N'Liefert genau eine Statuszeile für ein Work Item. Payload und ClaimToken werden bewusst nicht offengelegt.' AS nvarchar(max)),CAST(NULL AS nvarchar(max))),
          ('PARAMETER',1,N'@WorkItemId','bigint',1,0,NULL,N'Eindeutige Queue-ID.',NULL),
          ('PARAMETER',2,N'@ResultTable','sysname',0,1,NULL,N'Optionale lokale Temp-Tabelle für die Statuszeile.',NULL),
          ('PARAMETER',3,N'@KeepData','bit',0,0,N'0',N'Steuert die ResultTable-Vorbereitung.',NULL),
          ('PARAMETER',4,N'@Debug','tinyint',0,0,N'0',N'Erzeugt bei Werten größer 0 eine abstrakte Informationsmeldung.',NULL),
          ('PARAMETER',5,N'@Hilfe','bit',0,0,N'0',N'1 gibt ausschließlich dieses Help-Resultset aus.',NULL),
          ('RESULT_COLUMN',1,N'WorkItemId','bigint',0,0,NULL,N'Eindeutige Queue-ID.',NULL),
          ('RESULT_COLUMN',2,N'WorkTypeName','varchar(128)',0,0,NULL,N'Kanonischer Work-Type-Name.',NULL),
          ('RESULT_COLUMN',3,N'Status','varchar(16)',0,0,NULL,N'QUEUED, CLAIMED, COMPLETED oder FAILED.',NULL),
          ('RESULT_COLUMN',4,N'EnqueuedAtUtc','datetime2(7)',0,0,NULL,N'UTC-Zeitpunkt der Einreihung.',NULL),
          ('RESULT_COLUMN',5,N'EnqueuedBy','sysname',0,0,NULL,N'Original-Login der Einreihung.',NULL),
          ('RESULT_COLUMN',6,N'ClaimedAtUtc','datetime2(7)',0,1,NULL,N'UTC-Zeitpunkt des Claims.',NULL),
          ('RESULT_COLUMN',7,N'ClaimedBy','sysname',0,1,NULL,N'Original-Login des Claimers.',NULL),
          ('RESULT_COLUMN',8,N'CompletedAtUtc','datetime2(7)',0,1,NULL,N'UTC-Zeitpunkt eines erfolgreichen Abschlusses.',NULL),
          ('RESULT_COLUMN',9,N'CompletedBy','sysname',0,1,NULL,N'Original-Login des erfolgreichen Abschlusses.',NULL),
          ('RESULT_COLUMN',10,N'FailedAtUtc','datetime2(7)',0,1,NULL,N'UTC-Zeitpunkt eines Fehlabschlusses.',NULL),
          ('RESULT_COLUMN',11,N'FailedBy','sysname',0,1,NULL,N'Original-Login des Fehlabschlusses.',NULL),
          ('RESULT_COLUMN',12,N'FailureCode','varchar(64)',0,1,NULL,N'Optionaler stabiler Fehlercode.',NULL),
          ('RESULT_COLUMN',13,N'FailureMessage','nvarchar(1000)',0,1,NULL,N'Optionale bereinigte Fehlermeldung.',NULL),
          ('RESULT_COLUMN',14,N'RowVersion','binary(8)',0,0,NULL,N'Aktueller Concurrency-Marker.',NULL),
          ('RESULT_COLUMN',15,N'ClaimGeneration','bigint',0,0,NULL,N'Monotoner Ownership-Zähler.',NULL),
          ('RESULT_COLUMN',16,N'LeaseDurationSeconds','int',0,1,NULL,N'Dauer der aktuellen oder letzten Lease.',NULL),
          ('RESULT_COLUMN',17,N'LeaseUntilUtc','datetime2(7)',0,1,NULL,N'Exklusive UTC-Grenze der aktuellen oder letzten Lease.',NULL),
          ('RESULT_COLUMN',18,N'LastHeartbeatAtUtc','datetime2(7)',0,1,NULL,N'Zeitpunkt des letzten Heartbeats.',NULL),
          ('RESULT_COLUMN',19,N'IsLeaseExpired','bit',0,0,NULL,N'1 nur bei aktuell CLAIMED und abgelaufener Lease.',NULL),
          ('RESULT_COLUMN',20,N'RecoveryCount','bigint',0,0,NULL,N'Kumulierte kontrollierte Recoveries.',NULL),
          ('RESULT_COLUMN',21,N'LastRecoveredAtUtc','datetime2(7)',0,1,NULL,N'Zeitpunkt der letzten Recovery.',NULL),
          ('RESULT_COLUMN',22,N'LastRecoveredBy','sysname',0,1,NULL,N'Original-Login der letzten Recovery.',NULL),
          ('ERROR',1,N'51930-51934',NULL,NULL,NULL,NULL,N'Parameter-, Not-found- oder ResultTable-Fehler.',NULL),
          ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Liest den Status eines synthetischen Items.',N'EXEC toolbelt_core.USP_GetWorkStatus @WorkItemId=1;')
        )v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 ELSE 5 END,v.Ordinal;
        RETURN 0;
    END;
    IF @WorkItemId IS NULL OR @WorkItemId<=0 THROW 51930,N'@WorkItemId muss positiv sein.',1;
    CREATE TABLE #tbx_WorkQueue_StatusShape
    (WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) NULL,RowVersion binary(8) NOT NULL,ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,IsLeaseExpired bit NOT NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname NULL);
    CREATE TABLE #tbx_WorkQueue_StatusResult
    (WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) NULL,RowVersion binary(8) NOT NULL,ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,IsLeaseExpired bit NOT NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname NULL);
    INSERT INTO #tbx_WorkQueue_StatusResult SELECT * FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@WorkItemId;
    IF NOT EXISTS(SELECT 1 FROM #tbx_WorkQueue_StatusResult) THROW 51931,N'Das Work Item existiert nicht.',1;
    IF @ResultTable IS NOT NULL
    BEGIN
        IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL THROW 51934,N'Für @ResultTable fehlt toolbelt.core.result-table.',1;
        EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_WorkQueue_StatusShape',@KeepData=@KeepData;
        DECLARE @InsertSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N' (WorkItemId,WorkTypeName,Status,EnqueuedAtUtc,EnqueuedBy,ClaimedAtUtc,ClaimedBy,CompletedAtUtc,CompletedBy,FailedAtUtc,FailedBy,FailureCode,FailureMessage,RowVersion,ClaimGeneration,LeaseDurationSeconds,LeaseUntilUtc,LastHeartbeatAtUtc,IsLeaseExpired,RecoveryCount,LastRecoveredAtUtc,LastRecoveredBy) SELECT WorkItemId,WorkTypeName,Status,EnqueuedAtUtc,EnqueuedBy,ClaimedAtUtc,ClaimedBy,CompletedAtUtc,CompletedBy,FailedAtUtc,FailedBy,FailureCode,FailureMessage,RowVersion,ClaimGeneration,LeaseDurationSeconds,LeaseUntilUtc,LastHeartbeatAtUtc,IsLeaseExpired,RecoveryCount,LastRecoveredAtUtc,LastRecoveredBy FROM #tbx_WorkQueue_StatusResult;';
        EXEC sys.sp_executesql @InsertSql;
    END;
    IF @Debug>0 RAISERROR(N'USP_GetWorkStatus: Statuszeile gelesen.',10,1) WITH NOWAIT;
    IF @ResultTable IS NULL SELECT * FROM #tbx_WorkQueue_StatusResult;
    RETURN 0;
END;
GO
