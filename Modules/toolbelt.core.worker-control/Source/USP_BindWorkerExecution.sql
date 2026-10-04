-- Objekt: toolbelt_core.USP_BindWorkerExecution
-- Zweck: Bindet genau eine frische tatsächliche Handlerconnection vor Dispatch; kein Rebind.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: internal; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_BindWorkerExecution
 @SlotReservationId uniqueidentifier=NULL,
 @WorkerId uniqueidentifier=NULL,
 @WorkerGeneration bigint=NULL,
 @WorkerToken uniqueidentifier=NULL,
 @ClaimGeneration bigint=NULL,
 @ClaimToken uniqueidentifier=NULL,
 @ExecutionId uniqueidentifier=NULL,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_BindWorkerExecution' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Bindet genau eine frische tatsächliche Handlerconnection vor Dispatch; kein Rebind.',NULL),
 ('PARAMETER',1,N'@SlotReservationId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: SlotReservationId',NULL),
 ('PARAMETER',2,N'@WorkerId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkerId',NULL),
 ('PARAMETER',3,N'@WorkerGeneration',N'bigint',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkerGeneration',NULL),
 ('PARAMETER',4,N'@WorkerToken',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkerToken',NULL),
 ('PARAMETER',5,N'@ClaimGeneration',N'bigint',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ClaimGeneration',NULL),
 ('PARAMETER',6,N'@ClaimToken',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ClaimToken',NULL),
 ('PARAMETER',7,N'@ExecutionId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ExecutionId',NULL),
 ('PARAMETER',8,N'@Debug',N'tinyint',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',9,N'@Hilfe',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,NULL,NULL,NULL,NULL,NULL,N'Kein fachliches Resultset; OUTPUT und Returncode siehe Parametervertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_BindWorkerExecution @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql); RETURN 0; END;
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Bind erfolgt vor der Handlertransaktion.',3;
 DECLARE @Resource nvarchar(255)=N'Toolbelt.Worker.Attempt.'+CONVERT(nvarchar(36),@SlotReservationId),@Lock int,@Nonce uniqueidentifier=NEWID();
 EXEC @Lock=sys.sp_getapplock @Resource=@Resource,@LockMode=N'Exclusive',@LockOwner=N'Session',@LockTimeout=0,@DbPrincipal=N'public';
 IF @Lock<0 THROW 54218,N'Die Ausführung ist bereits an eine Handlerconnection gebunden.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation r WITH(UPDLOCK,HOLDLOCK) JOIN toolbelt_core.WorkerRegistration w ON w.WorkerId=r.WorkerId AND w.WorkerGeneration=r.WorkerGeneration
 WHERE r.SlotReservationId=@SlotReservationId AND r.WorkerId=@WorkerId AND r.WorkerGeneration=@WorkerGeneration AND w.WorkerToken=@WorkerToken AND w.OwnerPrincipalId=USER_ID()
 AND r.ClaimGeneration=@ClaimGeneration AND r.ClaimToken=@ClaimToken AND r.ExecutionId=@ExecutionId AND r.State='RESERVED' AND r.AttemptNonce IS NULL AND r.IsOccupied=1)
 THROW 54218,N'Die exakte Reservation besitzt keine frische Bindungsautorität.',2;
 IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition WHERE SlotReservationId=@SlotReservationId AND IsHeld=1) THROW 54219,N'Stop/Hold verhindert Dispatch.',1;
 EXEC sys.sp_set_session_context @key=N'toolbelt.worker.attempt_nonce',@value=@Nonce,@read_only=1;
 UPDATE toolbelt_core.WorkerSlotReservation SET AttemptNonce=@Nonce,BoundPrincipalId=USER_ID(),State='RUNNING' WHERE SlotReservationId=@SlotReservationId;
 COMMIT;
 END TRY BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 EXEC sys.sp_releaseapplock @Resource=@Resource,@LockOwner=N'Session',@DbPrincipal=N'public'; THROW;
 END CATCH;
 RETURN 0;
END;
GO
