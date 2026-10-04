-- Objekt: toolbelt_core.USP_StopWorkerExecution
-- Zweck: Persistiert generationgebunden Stop und Hold vor Providerabbruch; Completiongewinner bleibt committed.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: public; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_StopWorkerExecution
 @SlotReservationId uniqueidentifier=NULL,
 @ExpectedClaimGeneration bigint=NULL,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_StopWorkerExecution' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Persistiert generationgebunden Stop und Hold vor Providerabbruch; Completiongewinner bleibt committed.',NULL),
 ('PARAMETER',1,N'@SlotReservationId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: SlotReservationId',NULL),
 ('PARAMETER',2,N'@ExpectedClaimGeneration',N'bigint',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ExpectedClaimGeneration',NULL),
 ('PARAMETER',3,N'@ResultTable',N'sysname',0,1,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ResultTable',NULL),
 ('PARAMETER',4,N'@KeepData',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: KeepData',NULL),
 ('PARAMETER',5,N'@Debug',N'tinyint',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',6,N'@Hilfe',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,N'SlotReservationId',N'uniqueidentifier',0,0,NULL,N'SlotReservationId gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',2,N'ExecutionId',N'uniqueidentifier',0,0,NULL,N'ExecutionId gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',3,N'StopStatus',N'varchar(24)',0,0,NULL,N'StopStatus gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',4,N'HoldVersion',N'binary(8)',0,0,NULL,N'HoldVersion gemäß Ergebnisvertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_StopWorkerExecution @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql); RETURN 0; END;
 CREATE TABLE #tbx_USP_StopWorkerExecution_Result(SlotReservationId uniqueidentifier NOT NULL,ExecutionId uniqueidentifier NOT NULL,StopStatus varchar(24) NOT NULL,HoldVersion binary(8) NOT NULL);
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @DispositionResource nvarchar(255)=N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),@SlotReservationId),@Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=@DispositionResource,@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=5000,@DbPrincipal=N'public';
 IF @Lock<0 THROW 54222,N'Der private Disposition-Gate ist nicht verfügbar.',2;
 DECLARE @Item bigint,@Execution uniqueidentifier,@Generation bigint,@Outcome varchar(24),@State varchar(24),@Occupied bit,@Held bit;
 SELECT @Item=WorkItemId,@Execution=ExecutionId,@Generation=ClaimGeneration,@State=State,@Occupied=IsOccupied FROM toolbelt_core.WorkerSlotReservation WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId;
 IF @Item IS NULL OR @ExpectedClaimGeneration IS NULL OR @ExpectedClaimGeneration<>@Generation THROW 54224,N'Die ausgewählte Reservation oder Claimgeneration ist ungültig.',1;
 SELECT @Held=IsHeld FROM toolbelt_core.WorkerExecutionDisposition WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId;
 IF @Held IS NULL THROW 54224,N'Die aktuelle Disposition gehört nicht mehr zu dieser Reservation.',2;
 DECLARE @IsCompleted bit=0,@CommitWitness bit=0;
 -- Erst separat committed Queuezustand prüfen; laufender Witness bleibt uncommitted
 -- und darf unter dem Stopgate niemals gelesen werden.
 IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND Status='COMPLETED' AND ManagedReservationId=@SlotReservationId AND ClaimGeneration=@Generation) SET @IsCompleted=1;
 IF @IsCompleted=1
 BEGIN
 IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness WITH(READCOMMITTEDLOCK) WHERE SlotReservationId=@SlotReservationId AND ExecutionId=@Execution AND ClaimGeneration=@Generation) SET @CommitWitness=1;
 END;
 IF @Occupied=0 AND @State='ROLLED_BACK' AND @Held=0
 BEGIN
 -- Bewiesene freie Terminalhistory bleibt unverändert; kein neuer Hold für Retry.
 SET @Outcome='NONE';
 END
 ELSE IF @IsCompleted=1 AND @CommitWitness=1
 BEGIN
  UPDATE toolbelt_core.WorkerSlotReservation SET State='COMMITTED',IsOccupied=0,EndedAtUtc=ISNULL(EndedAtUtc,SYSUTCDATETIME()) WHERE SlotReservationId=@SlotReservationId;
  UPDATE toolbelt_core.WorkerExecutionDisposition SET IsHeld=0,StopStatus='ALREADY_COMMITTED' WHERE SlotReservationId=@SlotReservationId;
 END
 ELSE
 BEGIN
  UPDATE toolbelt_core.WorkerExecutionDisposition SET IsHeld=1,StopStatus=CASE WHEN @State='ROLLED_BACK' THEN 'ROLLED_BACK_HELD' ELSE 'REQUESTED' END WHERE SlotReservationId=@SlotReservationId;
  UPDATE toolbelt_core.WorkItem SET ManagedHold=1 WHERE WorkItemId=@Item AND ManagedReservationId=@SlotReservationId;
  UPDATE toolbelt_core.WorkerSlotReservation SET State=CASE WHEN State='ROLLED_BACK' THEN State ELSE 'STOP_REQUESTED' END WHERE SlotReservationId=@SlotReservationId AND IsOccupied=1;
 END;
 INSERT #tbx_USP_StopWorkerExecution_Result SELECT r.SlotReservationId,r.ExecutionId,d.StopStatus,d.HoldVersion FROM toolbelt_core.WorkerSlotReservation r JOIN toolbelt_core.WorkerExecutionDisposition d ON d.SlotReservationId=r.SlotReservationId WHERE r.SlotReservationId=@SlotReservationId;
 IF @ResultTable IS NOT NULL BEGIN
 EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_USP_StopWorkerExecution_Result',@KeepData=@KeepData;
 DECLARE @PublishSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N'(SlotReservationId,ExecutionId,StopStatus,HoldVersion) SELECT SlotReservationId,ExecutionId,StopStatus,HoldVersion FROM #tbx_USP_StopWorkerExecution_Result'; EXEC sys.sp_executesql @PublishSql; END;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 IF @ResultTable IS NULL SELECT SlotReservationId,ExecutionId,StopStatus,HoldVersion FROM #tbx_USP_StopWorkerExecution_Result;
 RETURN 0;
END;
GO
