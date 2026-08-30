SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_RenewWorkLease]
(
      @WorkItemId bigint           = NULL
    , @ClaimToken uniqueidentifier = NULL
    , @ResultTable sysname         = NULL
    , @KeepData    bit             = 0
    , @Debug       tinyint         = 0
    , @Hilfe       bit             = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;
    SET @KeepData=ISNULL(@KeepData,0); SET @Debug=ISNULL(@Debug,0); SET @Hilfe=ISNULL(@Hilfe,0);
    IF @Hilfe=1
    BEGIN
        SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_RenewWorkLease' AS sysname) ObjectName,
               v.Section,v.Ordinal,v.ItemName,v.SqlDataType,v.IsRequired,v.IsNullable,v.DefaultValue,v.Description,v.ExampleSql
        FROM (VALUES
          (CAST('DESCRIPTION' AS varchar(32)),1,CAST(NULL AS sysname),CAST(NULL AS varchar(256)),CAST(NULL AS bit),CAST(NULL AS bit),CAST(NULL AS nvarchar(4000)),CAST(N'Verlängert eine noch aktive Lease mit passendem ClaimToken um ihre beim Claim festgelegte Dauer ab Engine-Zeit. Eine abgelaufene Lease wird nicht wiederbelebt.' AS nvarchar(max)),CAST(NULL AS nvarchar(max))),
          ('PARAMETER',1,N'@WorkItemId','bigint',1,0,NULL,N'Eindeutige Queue-ID.',NULL),
          ('PARAMETER',2,N'@ClaimToken','uniqueidentifier',1,0,NULL,N'Geheimes Ownership-Token des aktiven Claims.',NULL),
          ('PARAMETER',3,N'@ResultTable','sysname',0,1,NULL,N'Optionale lokale Temp-Tabelle für die Lease-Zeile.',NULL),
          ('PARAMETER',4,N'@KeepData','bit',0,0,N'0',N'Steuert die ResultTable-Vorbereitung.',NULL),
          ('PARAMETER',5,N'@Debug','tinyint',0,0,N'0',N'Erzeugt eine abstrakte Informationsmeldung.',NULL),
          ('PARAMETER',6,N'@Hilfe','bit',0,0,N'0',N'1 gibt ausschließlich dieses Help-Resultset aus.',NULL),
          ('RESULT_COLUMN',1,N'WorkItemId','bigint',0,0,NULL,N'Eindeutige Queue-ID.',NULL),
          ('RESULT_COLUMN',2,N'ClaimGeneration','bigint',0,0,NULL,N'Aktuelle Ownership-Generation.',NULL),
          ('RESULT_COLUMN',3,N'LeaseUntilUtc','datetime2(7)',0,0,NULL,N'Neue exklusive UTC-Grenze der Lease.',NULL),
          ('RESULT_COLUMN',4,N'LastHeartbeatAtUtc','datetime2(7)',0,0,NULL,N'Engine-Zeit dieses Heartbeats.',NULL),
          ('ERROR',1,N'51950-51954',NULL,NULL,NULL,NULL,N'Caller-Transaktions-, Parameter-, Ownership-, Ablauf- oder ResultTable-Fehler.',NULL),
          ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Verlängert einen synthetischen aktiven Claim.',N'EXEC toolbelt_core.USP_RenewWorkLease @WorkItemId=1,@ClaimToken=''00000000-0000-0000-0000-000000000001'';')
        )v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 ELSE 5 END,v.Ordinal;
        RETURN 0;
    END;
    IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51950,N'USP_RenewWorkLease darf nicht innerhalb einer Caller-Transaktion ausgeführt werden.',1;
    IF @WorkItemId IS NULL OR @WorkItemId<=0 OR @ClaimToken IS NULL THROW 51951,N'@WorkItemId und @ClaimToken sind erforderlich.',1;

    CREATE TABLE #tbx_WorkQueue_LeaseShape(WorkItemId bigint NOT NULL,ClaimGeneration bigint NOT NULL,LeaseUntilUtc datetime2(7) NOT NULL,LastHeartbeatAtUtc datetime2(7) NOT NULL);
    CREATE TABLE #tbx_WorkQueue_LeaseResult(WorkItemId bigint NOT NULL,ClaimGeneration bigint NOT NULL,LeaseUntilUtc datetime2(7) NOT NULL,LastHeartbeatAtUtc datetime2(7) NOT NULL);
    DECLARE @NowUtc datetime2(7),@Status varchar(16),@CurrentToken uniqueidentifier,@LeaseUntilUtc datetime2(7),@LeaseDurationSeconds int;
    BEGIN TRY
        BEGIN TRANSACTION;
        SELECT @Status=Status,@CurrentToken=ClaimToken,@LeaseUntilUtc=LeaseUntilUtc,@LeaseDurationSeconds=LeaseDurationSeconds
        FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId;
        IF @Status IS NULL THROW 51952,N'Das Work Item existiert nicht.',1;
        IF @Status<>'CLAIMED' OR @CurrentToken<>@ClaimToken THROW 51952,N'Der Claim ist nicht aktiv oder @ClaimToken besitzt ihn nicht.',2;
        SET @NowUtc=SYSUTCDATETIME();
        IF @LeaseUntilUtc<=@NowUtc THROW 51953,N'Die Lease ist bereits abgelaufen und kann nicht wiederbelebt werden.',1;
        IF @ResultTable IS NOT NULL
        BEGIN
            IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL THROW 51954,N'Für @ResultTable fehlt toolbelt.core.result-table.',1;
            EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_WorkQueue_LeaseShape',@KeepData=@KeepData;
        END;
        UPDATE toolbelt_core.WorkItem SET LastHeartbeatAtUtc=@NowUtc,LeaseUntilUtc=DATEADD(SECOND,@LeaseDurationSeconds,@NowUtc)
        OUTPUT inserted.WorkItemId,inserted.ClaimGeneration,inserted.LeaseUntilUtc,inserted.LastHeartbeatAtUtc INTO #tbx_WorkQueue_LeaseResult
        WHERE WorkItemId=@WorkItemId AND Status='CLAIMED' AND ClaimToken=@ClaimToken AND LeaseUntilUtc>@NowUtc;
        IF @@ROWCOUNT<>1 THROW 51952,N'Der Claim-Zustand hat sich konkurrierend verändert.',3;
        IF @ResultTable IS NOT NULL
        BEGIN
            DECLARE @InsertSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N' (WorkItemId,ClaimGeneration,LeaseUntilUtc,LastHeartbeatAtUtc) SELECT WorkItemId,ClaimGeneration,LeaseUntilUtc,LastHeartbeatAtUtc FROM #tbx_WorkQueue_LeaseResult;';
            EXEC sys.sp_executesql @InsertSql;
        END;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    IF @Debug>0 RAISERROR(N'USP_RenewWorkLease: aktive Lease verlängert.',10,1) WITH NOWAIT;
    IF @ResultTable IS NULL SELECT * FROM #tbx_WorkQueue_LeaseResult;
    RETURN 0;
END;
GO
