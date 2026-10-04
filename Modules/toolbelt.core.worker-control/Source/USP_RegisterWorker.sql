-- ============================================================================
-- Objekt: toolbelt_core.USP_RegisterWorker
-- Zweck: Registriert eine neue principal- und generationgebundene Workeridentität; übernimmt keine alten Reservations.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene Rechte, keine Grants.
-- Sichtbarkeit: public
-- Transaktion: eigene kurze Steuertransaktion
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_RegisterWorker
 @WorkerId uniqueidentifier=NULL,
 @Capacity int=NULL,
 @RunMode varchar(16)='BOUNDED',
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_RegisterWorker' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,
 CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,
 CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Registriert eine neue principal- und generationgebundene Workeridentität; übernimmt keine alten Reservations.',NULL),
 ('PARAMETER',1,N'@WorkerId',N'uniqueidentifier',1,1,N'NULL',N'Technischer Parameter gemäß Worker-Control-Vertrag: WorkerId',NULL),
 ('PARAMETER',2,N'@Capacity',N'int',1,1,N'NULL',N'Technischer Parameter gemäß Worker-Control-Vertrag: Capacity',NULL),
 ('PARAMETER',3,N'@RunMode',N'varchar(16)',0,1,N'''BOUNDED''',N'Technischer Parameter gemäß Worker-Control-Vertrag: RunMode',NULL),
 ('PARAMETER',4,N'@ResultTable',N'sysname',0,1,N'NULL',N'Technischer Parameter gemäß Worker-Control-Vertrag: ResultTable',NULL),
 ('PARAMETER',5,N'@KeepData',N'bit',0,1,N'0',N'Technischer Parameter gemäß Worker-Control-Vertrag: KeepData',NULL),
 ('PARAMETER',6,N'@Debug',N'tinyint',0,1,N'0',N'Technischer Parameter gemäß Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',7,N'@Hilfe',N'bit',0,1,N'0',N'Technischer Parameter gemäß Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,N'WorkerId',N'uniqueidentifier',0,0,NULL,N'WorkerId gemäß stabilem Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',2,N'WorkerGeneration',N'bigint',0,0,NULL,N'WorkerGeneration gemäß stabilem Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',3,N'WorkerToken',N'uniqueidentifier',0,0,NULL,N'WorkerToken gemäß stabilem Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',4,N'ConfigVersion',N'binary(8)',0,0,NULL,N'ConfigVersion gemäß stabilem Ergebnisvertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Ausschließlich synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_RegisterWorker @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql);
 RETURN 0; END;
 CREATE TABLE #tbx_USP_RegisterWorker_Result(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,WorkerToken uniqueidentifier NOT NULL,ConfigVersion binary(8) NOT NULL);
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @GateId tinyint,@SchedulerId int,@Config binary(8);
 SELECT @GateId=GateId FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE GateId=1;
 SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
 SELECT @Config=ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WITH(UPDLOCK,HOLDLOCK) WHERE ConfigurationId=1;
 IF @GateId IS NULL OR @SchedulerId IS NULL OR @Config IS NULL THROW 54211,N'Der Worker-Control-Integrationsvertrag fehlt.',1;
 IF @WorkerId IS NULL OR @Capacity IS NULL OR @Capacity<1 OR @RunMode IS NULL OR @RunMode COLLATE Latin1_General_100_BIN2 NOT IN('BOUNDED','CONTINUOUS') OR DATALENGTH(@RunMode)<>LEN(@RunMode) THROW 54213,N'Die Workerregistrierung ist ungültig.',3;
 DECLARE @Generation bigint,@Token uniqueidentifier=NEWID(),@PreviousState varchar(16),@AdmissionPaused bit,@Owner int;
 SELECT TOP(1) @Generation=WorkerGeneration,@PreviousState=State,@AdmissionPaused=AdmissionPaused,@Owner=OwnerPrincipalId FROM toolbelt_core.WorkerRegistration WITH(UPDLOCK,HOLDLOCK) WHERE WorkerId=@WorkerId ORDER BY WorkerGeneration DESC;
 IF @Owner IS NOT NULL AND @Owner<>USER_ID() THROW 54214,N'Die stabile Workeridentität gehört einem anderen Principal.',1;
 IF @Generation=9223372036854775807 THROW 54214,N'Die Workergeneration ist erschöpft.',2;
 UPDATE toolbelt_core.WorkerRegistration SET State='DRAINING' WHERE WorkerId=@WorkerId AND State IN('ACTIVE','PAUSED');
 SET @Generation=ISNULL(@Generation,0)+1;
 INSERT toolbelt_core.WorkerRegistration SELECT @WorkerId,@Generation,@Token,USER_ID(),'EXTERNAL',CASE WHEN @AdmissionPaused=1 THEN 'PAUSED' ELSE 'ACTIVE' END,ISNULL(@AdmissionPaused,0),@Capacity,@RunMode,SYSUTCDATETIME(),HeartbeatSeconds,UnreachableSeconds FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1;
 INSERT #tbx_USP_RegisterWorker_Result VALUES(@WorkerId,@Generation,@Token,@Config);
 IF @ResultTable IS NOT NULL BEGIN
 EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_USP_RegisterWorker_Result',@KeepData=@KeepData;
 DECLARE @PublishSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N'(WorkerId,WorkerGeneration,WorkerToken,ConfigVersion) SELECT WorkerId,WorkerGeneration,WorkerToken,ConfigVersion FROM #tbx_USP_RegisterWorker_Result';
 EXEC sys.sp_executesql @PublishSql; END;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 IF @ResultTable IS NULL SELECT WorkerId,WorkerGeneration,WorkerToken,ConfigVersion FROM #tbx_USP_RegisterWorker_Result;
 RETURN 0;
END;
GO
