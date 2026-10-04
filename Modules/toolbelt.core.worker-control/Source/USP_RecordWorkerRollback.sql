-- Objekt: toolbelt_core.USP_RecordWorkerRollback
-- Zweck: Persistiert nach tatsächlichem Transaktionsende einen locking fehlenden Witness; Hold finalisiert atomar, sonst bleibt Occupied bis Terminalentscheidung.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: internal; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_RecordWorkerRollback
 @SlotReservationId uniqueidentifier=NULL,
 @ClaimToken uniqueidentifier=NULL,
 @ExecutionId uniqueidentifier=NULL,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_RecordWorkerRollback' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Persistiert nach tatsächlichem Transaktionsende einen locking fehlenden Witness; Hold finalisiert atomar, sonst bleibt Occupied bis Terminalentscheidung.',NULL),
 ('PARAMETER',1,N'@SlotReservationId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: SlotReservationId',NULL),
 ('PARAMETER',2,N'@ClaimToken',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ClaimToken',NULL),
 ('PARAMETER',3,N'@ExecutionId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ExecutionId',NULL),
 ('PARAMETER',4,N'@Debug',N'tinyint',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',5,N'@Hilfe',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,NULL,NULL,NULL,NULL,NULL,N'Kein fachliches Resultset; OUTPUT und Returncode siehe Parametervertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_RecordWorkerRollback @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql); RETURN 0; END;
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 IF APPLOCK_MODE(N'public',N'Toolbelt.Worker.Attempt.'+CONVERT(nvarchar(36),@SlotReservationId),N'Session')<>N'Exclusive' THROW 54220,N'Der Rollbackpfad ist nicht an die tatsächliche Handlerconnection gebunden.',6;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @Resource nvarchar(255)=N'Toolbelt.Worker.Attempt.'+CONVERT(nvarchar(36),@SlotReservationId),@Nonce uniqueidentifier=TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.attempt_nonce')),@Item bigint,@Generation bigint;
 IF @SlotReservationId IS NULL OR @ClaimToken IS NULL OR @ExecutionId IS NULL OR @Nonce IS NULL OR APPLOCK_MODE(N'public',@Resource,N'Session')<>N'Exclusive' THROW 54220,N'Die tatsächliche Handlerconnection besitzt den Attempt nicht.',1;
 SELECT @Item=WorkItemId,@Generation=ClaimGeneration FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@SlotReservationId AND ClaimToken=@ClaimToken AND ExecutionId=@ExecutionId AND AttemptNonce=@Nonce AND BoundPrincipalId=USER_ID() AND IsOccupied=1;
 IF @Item IS NULL THROW 54220,N'Die Attemptbindung ist veraltet oder widersprüchlich.',2;
 IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId) THROW 54223,N'Persistierter Witness verhindert einen Rollbacknachweis.',1;
 DECLARE @DispositionResource nvarchar(255)=N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),@SlotReservationId),@Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=@DispositionResource,@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=5000,@DbPrincipal=N'public';
 IF @Lock<0 THROW 54222,N'Der private Disposition-Gate ist nicht verfügbar.',2;
 UPDATE toolbelt_core.WorkerSlotReservation SET State='ROLLED_BACK' WHERE SlotReservationId=@SlotReservationId AND IsOccupied=1;
 IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId AND IsHeld=1)
 BEGIN
 UPDATE toolbelt_core.WorkItem SET Status='FAILED',FailedAtUtc=SYSUTCDATETIME(),FailedBy=ORIGINAL_LOGIN(),FailureCode='WORKER.STOP_HELD',FailureMessage=NULL,ManagedHold=1,ManagedCompletionNonce=NULL
 WHERE WorkItemId=@Item AND ManagedReservationId=@SlotReservationId AND ClaimGeneration=@Generation AND ClaimToken=@ClaimToken AND Status='CLAIMED';
 IF @@ROWCOUNT<>1 THROW 54220,N'Der bewiesene Rollback gehört keinem unveränderten Claim.',5;
 UPDATE toolbelt_core.WorkerSlotReservation SET State='ROLLED_BACK',IsOccupied=0,EndedAtUtc=SYSUTCDATETIME() WHERE SlotReservationId=@SlotReservationId;
 UPDATE toolbelt_core.WorkerExecutionDisposition SET IsHeld=1,StopStatus='ROLLED_BACK_HELD' WHERE SlotReservationId=@SlotReservationId;
 END;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 RETURN 0;
END;
GO
