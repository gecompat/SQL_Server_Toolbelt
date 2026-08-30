SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_FailWork]
(
      @WorkItemId    bigint           = NULL
    , @ClaimToken    uniqueidentifier = NULL
    , @FailureCode   varchar(64)      = NULL
    , @FailureMessage nvarchar(max)   = NULL
    , @ResultTable   sysname          = NULL
    , @KeepData      bit              = 0
    , @Debug         tinyint          = 0
    , @Hilfe         bit              = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;
    SET @KeepData=ISNULL(@KeepData,0); SET @Debug=ISNULL(@Debug,0); SET @Hilfe=ISNULL(@Hilfe,0);
    IF @Hilfe=1
    BEGIN
        SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_FailWork' AS sysname) ObjectName,
               v.Section,v.Ordinal,v.ItemName,v.SqlDataType,v.IsRequired,v.IsNullable,v.DefaultValue,v.Description,v.ExampleSql
        FROM (VALUES
          (CAST('DESCRIPTION' AS varchar(32)),1,CAST(NULL AS sysname),CAST(NULL AS varchar(256)),CAST(NULL AS bit),CAST(NULL AS bit),CAST(NULL AS nvarchar(4000)),CAST(N'Schließt genau ein CLAIMED Work Item mit passendem ClaimToken als FAILED ab. Gespeichert werden nur ein stabiler Code und eine optionale bereinigte Kurzmeldung.' AS nvarchar(max)),CAST(NULL AS nvarchar(max))),
          ('PARAMETER',1,N'@WorkItemId','bigint',1,0,NULL,N'Eindeutige Queue-ID.',NULL),
          ('PARAMETER',2,N'@ClaimToken','uniqueidentifier',1,0,NULL,N'Vom Claim zurückgegebenes Ownership-Token.',NULL),
          ('PARAMETER',3,N'@FailureCode','varchar(64)',1,0,NULL,N'Case-sensitiver ASCII-Code aus Buchstaben, Ziffern, Punkt, Unterstrich und Bindestrich.',NULL),
          ('PARAMETER',4,N'@FailureMessage','nvarchar(max)',0,1,NULL,N'Vom Aufrufer bereinigte Meldung mit höchstens 1000 Unicode-Codeeinheiten; keine Logs oder Stack Traces.',NULL),
          ('PARAMETER',5,N'@ResultTable','sysname',0,1,NULL,N'Optionale lokale Temp-Tabelle für die Statuszeile.',NULL),
          ('PARAMETER',6,N'@KeepData','bit',0,0,N'0',N'Steuert die ResultTable-Vorbereitung.',NULL),
          ('PARAMETER',7,N'@Debug','tinyint',0,0,N'0',N'Erzeugt bei Werten größer 0 eine abstrakte Informationsmeldung.',NULL),
          ('PARAMETER',8,N'@Hilfe','bit',0,0,N'0',N'1 gibt ausschließlich dieses Help-Resultset aus.',NULL),
          ('RESULT_COLUMN',1,N'WorkItemId','bigint',0,0,NULL,N'Eindeutige Queue-ID.',NULL),
          ('RESULT_COLUMN',2,N'WorkTypeName','varchar(128)',0,0,NULL,N'Kanonischer Work-Type-Name.',NULL),
          ('RESULT_COLUMN',3,N'Status','varchar(16)',0,0,NULL,N'Nach Erfolg stets FAILED.',NULL),
          ('RESULT_COLUMN',4,N'EnqueuedAtUtc','datetime2(7)',0,0,NULL,N'UTC-Zeitpunkt der Einreihung.',NULL),
          ('RESULT_COLUMN',5,N'EnqueuedBy','sysname',0,0,NULL,N'Original-Login der Einreihung.',NULL),
          ('RESULT_COLUMN',6,N'ClaimedAtUtc','datetime2(7)',0,1,NULL,N'UTC-Zeitpunkt des Claims.',NULL),
          ('RESULT_COLUMN',7,N'ClaimedBy','sysname',0,1,NULL,N'Original-Login des Claimers.',NULL),
          ('RESULT_COLUMN',8,N'CompletedAtUtc','datetime2(7)',0,1,NULL,N'Bei FAILED NULL.',NULL),
          ('RESULT_COLUMN',9,N'CompletedBy','sysname',0,1,NULL,N'Bei FAILED NULL.',NULL),
          ('RESULT_COLUMN',10,N'FailedAtUtc','datetime2(7)',0,1,NULL,N'UTC-Zeitpunkt des Fehlabschlusses.',NULL),
          ('RESULT_COLUMN',11,N'FailedBy','sysname',0,1,NULL,N'Original-Login des Fail-Aufrufs.',NULL),
          ('RESULT_COLUMN',12,N'FailureCode','varchar(64)',0,1,NULL,N'Stabiler case-sensitiver Fehlercode.',NULL),
          ('RESULT_COLUMN',13,N'FailureMessage','nvarchar(1000)',0,1,NULL,N'Optionale bereinigte Fehlermeldung.',NULL),
          ('RESULT_COLUMN',14,N'RowVersion','binary(8)',0,0,NULL,N'Aktueller Concurrency-Marker.',NULL),
          ('ERROR',1,N'51925-51929',NULL,NULL,NULL,NULL,N'Parameter-, Zustands-, Token-, Transaktions- oder ResultTable-Fehler.',NULL),
          ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Markiert einen synthetischen Auftrag als fehlgeschlagen.',N'EXEC toolbelt_core.USP_FailWork @WorkItemId=1,@ClaimToken=''00000000-0000-0000-0000-000000000001'',@FailureCode=''DEMO.ERROR'';')
        )v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 ELSE 5 END,v.Ordinal;
        RETURN 0;
    END;
    IF @WorkItemId IS NULL OR @WorkItemId<=0 OR @ClaimToken IS NULL THROW 51925,N'@WorkItemId und @ClaimToken sind erforderlich.',1;
    IF @FailureCode IS NULL OR LEN(@FailureCode) NOT BETWEEN 1 AND 64 OR @FailureCode NOT LIKE '[A-Za-z]%' COLLATE Latin1_General_100_BIN2 OR @FailureCode LIKE '%[^A-Za-z0-9._-]%' COLLATE Latin1_General_100_BIN2 THROW 51926,N'@FailureCode ist kein gültiger stabiler ASCII-Code.',1;
    IF DATALENGTH(@FailureMessage)>2000 THROW 51927,N'@FailureMessage darf höchstens 1000 Unicode-Codeeinheiten enthalten.',1;
    IF XACT_STATE()=-1 THROW 51929,N'Ein Work Item kann in einer uncommittable Caller-Transaktion nicht fehlgeschlagen gesetzt werden.',1;

    CREATE TABLE #tbx_WorkQueue_StatusShape
    (WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) NULL,RowVersion binary(8) NOT NULL);
    CREATE TABLE #tbx_WorkQueue_StatusResult
    (WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) NULL,RowVersion binary(8) NOT NULL);
    DECLARE @InitialTranCount int=@@TRANCOUNT,@CurrentStatus varchar(16),@CurrentToken uniqueidentifier;
    IF @InitialTranCount=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION TBX_WorkQueue_Fail;
    BEGIN TRY
        SELECT @CurrentStatus=Status,@CurrentToken=ClaimToken FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId;
        IF @CurrentStatus IS NULL THROW 51928,N'Das Work Item existiert nicht.',1;
        IF @CurrentStatus<>'CLAIMED' THROW 51928,N'Nur ein CLAIMED Work Item kann fehlgeschlagen gesetzt werden.',2;
        IF @CurrentToken<>@ClaimToken THROW 51928,N'@ClaimToken besitzt das Work Item nicht.',3;
        IF @ResultTable IS NOT NULL
        BEGIN
            IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL THROW 51929,N'Für @ResultTable fehlt toolbelt.core.result-table.',2;
            EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_WorkQueue_StatusShape',@KeepData=@KeepData;
        END;
        UPDATE toolbelt_core.WorkItem SET Status='FAILED',FailedAtUtc=SYSUTCDATETIME(),FailedBy=ORIGINAL_LOGIN(),FailureCode=@FailureCode,FailureMessage=CONVERT(nvarchar(1000),@FailureMessage) WHERE WorkItemId=@WorkItemId AND Status='CLAIMED' AND ClaimToken=@ClaimToken;
        IF @@ROWCOUNT<>1 THROW 51928,N'Der Claim-Zustand hat sich konkurrierend verändert.',4;
        INSERT INTO #tbx_WorkQueue_StatusResult SELECT * FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@WorkItemId;
        IF @ResultTable IS NOT NULL
        BEGIN
            DECLARE @InsertSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N' (WorkItemId,WorkTypeName,Status,EnqueuedAtUtc,EnqueuedBy,ClaimedAtUtc,ClaimedBy,CompletedAtUtc,CompletedBy,FailedAtUtc,FailedBy,FailureCode,FailureMessage,RowVersion) SELECT WorkItemId,WorkTypeName,Status,EnqueuedAtUtc,EnqueuedBy,ClaimedAtUtc,ClaimedBy,CompletedAtUtc,CompletedBy,FailedAtUtc,FailedBy,FailureCode,FailureMessage,RowVersion FROM #tbx_WorkQueue_StatusResult;';
            EXEC sys.sp_executesql @InsertSql;
        END;
        IF @InitialTranCount=0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @InitialTranCount=0 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        ELSE IF @InitialTranCount>0 AND XACT_STATE()=1 ROLLBACK TRANSACTION TBX_WorkQueue_Fail;
        THROW;
    END CATCH;
    IF @Debug>0 RAISERROR(N'USP_FailWork: Work Item als FAILED abgeschlossen.',10,1) WITH NOWAIT;
    IF @ResultTable IS NULL SELECT * FROM #tbx_WorkQueue_StatusResult;
    RETURN 0;
END;
GO
