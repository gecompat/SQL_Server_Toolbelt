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
        SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_RecoverExpiredWork' AS sysname) ObjectName,
               v.Section,v.Ordinal,v.ItemName,v.SqlDataType,v.IsRequired,v.IsNullable,v.DefaultValue,v.Description,v.ExampleSql
        FROM (VALUES
          (CAST('DESCRIPTION' AS varchar(32)),1,CAST(NULL AS sysname),CAST(NULL AS varchar(256)),CAST(NULL AS bit),CAST(NULL AS bit),CAST(NULL AS nvarchar(4000)),CAST(N'Setzt explizit höchstens @MaxItems abgelaufene Claims auf QUEUED zurück. Alte ClaimTokens werden atomar invalidiert; es findet keine automatische Ausführung statt.' AS nvarchar(max)),CAST(NULL AS nvarchar(max))),
          ('PARAMETER',1,N'@MaxItems','int',0,0,N'100',N'Batchgrenze von 1 bis 1000.',NULL),
          ('PARAMETER',2,N'@ResultTable','sysname',0,1,NULL,N'Optionale lokale Temp-Tabelle für recoverte Items.',NULL),
          ('PARAMETER',3,N'@KeepData','bit',0,0,N'0',N'Steuert die ResultTable-Vorbereitung.',NULL),
          ('PARAMETER',4,N'@Debug','tinyint',0,0,N'0',N'Erzeugt eine abstrakte Informationsmeldung.',NULL),
          ('PARAMETER',5,N'@Hilfe','bit',0,0,N'0',N'1 gibt ausschließlich dieses Help-Resultset aus.',NULL),
          ('RESULT_COLUMN',1,N'WorkItemId','bigint',0,0,NULL,N'Eindeutige Queue-ID.',NULL),
          ('RESULT_COLUMN',2,N'WorkTypeName','varchar(128)',0,0,NULL,N'Kanonischer Work-Type-Name.',NULL),
          ('RESULT_COLUMN',3,N'Status','varchar(16)',0,0,NULL,N'Nach Recovery stets QUEUED.',NULL),
          ('RESULT_COLUMN',4,N'ClaimGeneration','bigint',0,0,NULL,N'Letzte invalidierte Ownership-Generation.',NULL),
          ('RESULT_COLUMN',5,N'RecoveryCount','bigint',0,0,NULL,N'Kumulierte Zahl kontrollierter Recoveries.',NULL),
          ('RESULT_COLUMN',6,N'LastRecoveredAtUtc','datetime2(7)',0,0,NULL,N'Engine-Zeit der Recovery.',NULL),
          ('RESULT_COLUMN',7,N'LastRecoveredBy','sysname',0,0,NULL,N'Original-Login der Recovery.',NULL),
          ('ERROR',1,N'51960-51964',NULL,NULL,NULL,NULL,N'Caller-Transaktions-, Batch- oder ResultTable-Fehler.',NULL),
          ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Recovert höchstens 100 abgelaufene Claims.',N'EXEC toolbelt_core.USP_RecoverExpiredWork @MaxItems=100;')
        )v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 ELSE 5 END,v.Ordinal;
        RETURN 0;
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
            WHERE Status='CLAIMED' AND LeaseUntilUtc<=@NowUtc
            ORDER BY LeaseUntilUtc,WorkItemId
        )
        UPDATE Expired SET
              Status='QUEUED',ClaimedAtUtc=NULL,ClaimedBy=NULL,ClaimToken=NULL
            , LeaseDurationSeconds=NULL,LeaseUntilUtc=NULL,LastHeartbeatAtUtc=NULL
            , RecoveryCount=RecoveryCount+1,LastRecoveredAtUtc=@NowUtc,LastRecoveredBy=@RecoveredBy
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
