-- ============================================================================
-- Objekt: toolbelt_core.USP_SetWorkerState
-- Zweck: Steuert ACTIVE, PAUSED oder DRAINING einer exakten lebenden Workergeneration.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene Rechte, keine Grants.
-- Sichtbarkeit: public
-- Transaktion: eigene kurze Steuertransaktion
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_SetWorkerState
 @WorkerId uniqueidentifier=NULL,
 @WorkerGeneration bigint=NULL,
 @RequestedState varchar(16)=NULL,
 @ExpectedConfigVersion binary(8)=NULL,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_SetWorkerState' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,
 CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,
 CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Steuert ACTIVE, PAUSED oder DRAINING einer exakten lebenden Workergeneration.',NULL),
 ('PARAMETER',1,N'@WorkerId',N'uniqueidentifier',1,1,N'NULL',N'Technischer Parameter gemäß Worker-Control-Vertrag: WorkerId',NULL),
 ('PARAMETER',2,N'@WorkerGeneration',N'bigint',1,1,N'NULL',N'Technischer Parameter gemäß Worker-Control-Vertrag: WorkerGeneration',NULL),
 ('PARAMETER',3,N'@RequestedState',N'varchar(16)',1,1,N'NULL',N'Technischer Parameter gemäß Worker-Control-Vertrag: RequestedState',NULL),
 ('PARAMETER',4,N'@ExpectedConfigVersion',N'binary(8)',1,1,N'NULL',N'Technischer Parameter gemäß Worker-Control-Vertrag: ExpectedConfigVersion',NULL),
 ('PARAMETER',5,N'@ResultTable',N'sysname',0,1,N'NULL',N'Technischer Parameter gemäß Worker-Control-Vertrag: ResultTable',NULL),
 ('PARAMETER',6,N'@KeepData',N'bit',0,1,N'0',N'Technischer Parameter gemäß Worker-Control-Vertrag: KeepData',NULL),
 ('PARAMETER',7,N'@Debug',N'tinyint',0,1,N'0',N'Technischer Parameter gemäß Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',8,N'@Hilfe',N'bit',0,1,N'0',N'Technischer Parameter gemäß Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,N'WorkerId',N'uniqueidentifier',0,0,NULL,N'WorkerId gemäß stabilem Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',2,N'WorkerGeneration',N'bigint',0,0,NULL,N'WorkerGeneration gemäß stabilem Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',3,N'State',N'varchar(16)',0,0,NULL,N'State gemäß stabilem Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',4,N'ConfigVersion',N'binary(8)',0,0,NULL,N'ConfigVersion gemäß stabilem Ergebnisvertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Ausschließlich synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_SetWorkerState @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql);
 RETURN 0; END;
 CREATE TABLE #tbx_USP_SetWorkerState_Result(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,State varchar(16) NOT NULL,ConfigVersion binary(8) NOT NULL);
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @GateId tinyint,@SchedulerId int,@Config binary(8);
 SELECT @GateId=GateId FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE GateId=1;
 SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
 SELECT @Config=ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WITH(UPDLOCK,HOLDLOCK) WHERE ConfigurationId=1;
 IF @GateId IS NULL OR @SchedulerId IS NULL OR @Config IS NULL THROW 54211,N'Der Worker-Control-Integrationsvertrag fehlt.',1;
 IF @ExpectedConfigVersion IS NULL OR @ExpectedConfigVersion<>@Config THROW 54212,N'Die erwartete Konfigurationsversion ist veraltet oder fehlt.',1;
 IF @RequestedState IS NULL OR @RequestedState COLLATE Latin1_General_100_BIN2 NOT IN('ACTIVE','PAUSED','DRAINING') OR DATALENGTH(@RequestedState)<>LEN(@RequestedState) THROW 54213,N'Der angeforderte Zustand ist ungültig.',5;
 IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration WHERE WorkerId=@WorkerId AND WorkerGeneration>@WorkerGeneration) THROW 54215,N'Adminsteuerung benötigt die aktuellste stabile Workergeneration.',5;
 UPDATE toolbelt_core.WorkerRegistration SET AdmissionPaused=CASE WHEN @RequestedState='ACTIVE' THEN 0 ELSE 1 END WHERE WorkerId=@WorkerId;
 UPDATE toolbelt_core.WorkerRegistration SET State=@RequestedState WHERE WorkerId=@WorkerId AND WorkerGeneration=@WorkerGeneration AND State NOT IN('CLOSED','UNREACHABLE') AND DATEADD(SECOND,UnreachableSeconds,LastHeartbeatAtUtc)>SYSUTCDATETIME();
 IF @@ROWCOUNT<>1 THROW 54215,N'Die gewählte Generation ist nicht lebend.',4;
 UPDATE toolbelt_core.WorkerControlConfiguration SET MaxConcurrentExecutions=MaxConcurrentExecutions WHERE ConfigurationId=1;
 INSERT #tbx_USP_SetWorkerState_Result SELECT w.WorkerId,w.WorkerGeneration,w.State,c.ConfigVersion FROM toolbelt_core.WorkerRegistration w CROSS JOIN toolbelt_core.WorkerControlConfiguration c WHERE w.WorkerId=@WorkerId AND w.WorkerGeneration=@WorkerGeneration AND c.ConfigurationId=1;
 IF @ResultTable IS NOT NULL BEGIN
 EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_USP_SetWorkerState_Result',@KeepData=@KeepData;
 DECLARE @PublishSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N'(WorkerId,WorkerGeneration,State,ConfigVersion) SELECT WorkerId,WorkerGeneration,State,ConfigVersion FROM #tbx_USP_SetWorkerState_Result';
 EXEC sys.sp_executesql @PublishSql; END;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 IF @ResultTable IS NULL SELECT WorkerId,WorkerGeneration,State,ConfigVersion FROM #tbx_USP_SetWorkerState_Result;
 RETURN 0;
END;
GO
