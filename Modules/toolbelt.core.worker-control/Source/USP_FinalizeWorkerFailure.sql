-- Objekt: toolbelt_core.USP_FinalizeWorkerFailure
-- Zweck: Konsumiert bewiesenen Rollback und finalisiert expliziten Fail/Retry; frischer Hold oder abgelaufene Lease gewinnt.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: internal; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_FinalizeWorkerFailure
 @SlotReservationId uniqueidentifier=NULL,
 @ClaimToken uniqueidentifier=NULL,
 @ExecutionId uniqueidentifier=NULL,
 @FailureCode varchar(64)=NULL,
 @Retry bit=0,
 @Outcome varchar(24)=NULL OUTPUT,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_FinalizeWorkerFailure' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Konsumiert bewiesenen Rollback und finalisiert expliziten Fail/Retry; frischer Hold oder abgelaufene Lease gewinnt.',NULL),
 ('PARAMETER',1,N'@SlotReservationId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: SlotReservationId',NULL),
 ('PARAMETER',2,N'@ClaimToken',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ClaimToken',NULL),
 ('PARAMETER',3,N'@ExecutionId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ExecutionId',NULL),
 ('PARAMETER',4,N'@FailureCode',N'varchar(64)',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: FailureCode',NULL),
 ('PARAMETER',5,N'@Retry',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Retry',NULL),
 ('PARAMETER',6,N'@Outcome',N'varchar(24)',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Outcome',NULL),
 ('PARAMETER',7,N'@Debug',N'tinyint',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',8,N'@Hilfe',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,NULL,NULL,NULL,NULL,NULL,N'Kein fachliches Resultset; OUTPUT und Returncode siehe Parametervertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_FinalizeWorkerFailure @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql); RETURN 0; END;
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @Resource nvarchar(255)=N'Toolbelt.Worker.Attempt.'+CONVERT(nvarchar(36),@SlotReservationId),@Nonce uniqueidentifier=TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.attempt_nonce')),@Item bigint,@Generation bigint;
 IF @SlotReservationId IS NULL OR @ClaimToken IS NULL OR @ExecutionId IS NULL OR @Nonce IS NULL OR APPLOCK_MODE(N'public',@Resource,N'Session')<>N'Exclusive' THROW 54220,N'Die tatsächliche Handlerconnection besitzt den Attempt nicht.',1;
 SELECT @Item=WorkItemId,@Generation=ClaimGeneration FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@SlotReservationId AND ClaimToken=@ClaimToken AND ExecutionId=@ExecutionId AND AttemptNonce=@Nonce AND BoundPrincipalId=USER_ID() AND IsOccupied=1;
 IF @Item IS NULL THROW 54220,N'Die Attemptbindung ist veraltet oder widersprüchlich.',2;
 DECLARE @DispositionResource nvarchar(255)=N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),@SlotReservationId),@Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=@DispositionResource,@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=5000,@DbPrincipal=N'public';
 IF @Lock<0 THROW 54222,N'Der private Disposition-Gate ist nicht verfügbar.',2;
 IF @FailureCode IS NULL OR @Retry IS NULL THROW 54213,N'Die Terminalentscheidung verlangt gültige Fehlerdaten.',6;
 IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId AND State='ROLLED_BACK' AND IsOccupied=1)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId) THROW 54223,N'Der atomare Rollbacknachweis fehlt.',2;
 DECLARE @Held bit;SELECT @Held=IsHeld FROM toolbelt_core.WorkerExecutionDisposition WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId;
 IF @Held IS NULL THROW 54223,N'Die exakte Disposition fehlt.',3;
 IF @Held=1 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND LeaseUntilUtc<=SYSUTCDATETIME())
 BEGIN
 UPDATE toolbelt_core.WorkItem SET Status='FAILED',FailedAtUtc=SYSUTCDATETIME(),FailedBy=ORIGINAL_LOGIN(),FailureCode='WORKER.STOP_HELD',FailureMessage=NULL,ManagedHold=1,ManagedCompletionNonce=NULL
 WHERE WorkItemId=@Item AND ManagedReservationId=@SlotReservationId AND ClaimGeneration=@Generation AND ClaimToken=@ClaimToken AND Status='CLAIMED';
 IF @@ROWCOUNT<>1 THROW 54220,N'Der bewiesene Rollback gehört keinem unveränderten Claim.',5;
 UPDATE toolbelt_core.WorkerSlotReservation SET State='ROLLED_BACK',IsOccupied=0,EndedAtUtc=SYSUTCDATETIME() WHERE SlotReservationId=@SlotReservationId;
 UPDATE toolbelt_core.WorkerExecutionDisposition SET IsHeld=1,StopStatus='ROLLED_BACK_HELD' WHERE SlotReservationId=@SlotReservationId;
 SET @Outcome='ROLLED_BACK_HELD';
 END
 ELSE
 BEGIN
  DECLARE @TerminalNonce uniqueidentifier=NEWID();
  EXEC sys.sp_set_session_context @key=N'toolbelt.worker.completion_nonce',@value=@TerminalNonce;
  UPDATE toolbelt_core.WorkItem SET ManagedCompletionNonce=@TerminalNonce WHERE WorkItemId=@Item AND ManagedReservationId=@SlotReservationId AND ClaimGeneration=@Generation AND ClaimToken=@ClaimToken AND Status='CLAIMED' AND ManagedHold=0;
  IF @@ROWCOUNT<>1 THROW 54220,N'Der Terminalclaim ist verändert.',7;
  IF @Retry=1 EXEC toolbelt_core.USP_ScheduleWorkRetryCore @EmitResult=0,@WorkItemId=@Item,@ClaimToken=@ClaimToken,@FailureCode=@FailureCode;
  ELSE EXEC toolbelt_core.USP_FailWorkCore @EmitResult=0,@WorkItemId=@Item,@ClaimToken=@ClaimToken,@FailureCode=@FailureCode;
  SELECT @Outcome=Status FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item;
  -- Nur bewiesen beendete, heldfreie exakte Queueentscheidung lösen; Attempt/History bleiben.
  UPDATE toolbelt_core.WorkItem SET ManagedCompletionNonce=NULL,ManagedReservationId=NULL
  WHERE WorkItemId=@Item AND ManagedReservationId=@SlotReservationId AND ClaimGeneration=@Generation AND ManagedHold=0 AND Status IN('FAILED','RETRY_WAIT','DEAD_LETTER');
  IF @@ROWCOUNT<>1 THROW 54220,N'Die heldfreie Terminalentscheidung ist nicht exakt.',8;
  UPDATE toolbelt_core.WorkerSlotReservation SET IsOccupied=0,EndedAtUtc=SYSUTCDATETIME() WHERE SlotReservationId=@SlotReservationId;
 END;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 RETURN 0;
END;
GO
