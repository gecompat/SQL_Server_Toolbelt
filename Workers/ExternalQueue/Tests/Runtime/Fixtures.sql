-- Ausschließlich synthetische Handler in der eigenen Disposable-Testdatenbank.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE TABLE dbo.TbxWorkerLedger
(
 WorkItemId bigint NOT NULL PRIMARY KEY, Scenario varchar(32) NOT NULL,
 Marker nvarchar(100) NULL, ExecutionId uniqueidentifier NOT NULL,
 Generation bigint NOT NULL, Active bit NOT NULL
);
GO
CREATE PROCEDURE dbo.USP_TbxWorkerNone AS
BEGIN
 SET NOCOUNT ON;
 INSERT dbo.TbxWorkerLedger VALUES(CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.work_item_id')),
 'none',N'none',toolbelt_core.SVF_CurrentExecutionId(),
 CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.claim_generation')),0);
 RETURN 7;
END;
GO
CREATE PROCEDURE dbo.USP_TbxWorkerJson @PayloadJson nvarchar(max) AS
BEGIN
 SET NOCOUNT ON;
 INSERT dbo.TbxWorkerLedger VALUES(CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.work_item_id')),
 'json',JSON_VALUE(@PayloadJson,'$.marker'),toolbelt_core.SVF_CurrentExecutionId(),
 CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.claim_generation')),0);
END;
GO
CREATE PROCEDURE dbo.USP_TbxWorkerTerminal AS
BEGIN
 SET NOCOUNT ON;
 INSERT dbo.TbxWorkerLedger VALUES(CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.work_item_id')),
 'rollback',N'synthetic',toolbelt_core.SVF_CurrentExecutionId(),
 CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.claim_generation')),0);
 THROW 50010,N'Synthetic permanent failure',1;
END;
GO
CREATE PROCEDURE dbo.USP_TbxWorkerRetry AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Id bigint=CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.work_item_id'));
 INSERT dbo.TbxWorkerLedger VALUES(@Id,'retry',N'synthetic',toolbelt_core.SVF_CurrentExecutionId(),
 CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.claim_generation')),0);
 IF (SELECT CycleAttemptCount FROM toolbelt_core.WorkItem WHERE WorkItemId=@Id)=1
  THROW 50002,N'Synthetic opted-in transient failure',1;
END;
GO
CREATE PROCEDURE dbo.USP_TbxWorkerAlwaysTransient AS
BEGIN
 SET NOCOUNT ON;
 THROW 50002,N'Synthetic opted-in transient failure',1;
END;
GO
CREATE PROCEDURE dbo.USP_TbxWorkerCancellation AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Id bigint=CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.work_item_id')),
 @Execution uniqueidentifier=CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.execution_id')),@Steps int=0;
 IF @Execution IS NULL OR toolbelt_core.SVF_CurrentExecutionId()<>@Execution THROW 50010,N'Synthetic execution identity drift',1;
 INSERT dbo.TbxWorkerLedger VALUES(@Id,'cancel',N'synthetic',@Execution,
 CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.claim_generation')),1);
 -- Jeder begrenzte Schritt beobachtet die eigene persistierte Anforderung.
 WHILE @Steps<100
 BEGIN
  IF toolbelt_core.SVF_CurrentExecutionId()<>@Execution OR NOT EXISTS
  (SELECT 1 FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@Id AND Status='CLAIMED'
   AND ClaimGeneration=CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.claim_generation')) AND IsLeaseExpired=0)
   THROW 50010,N'Synthetic cooperative ownership checkpoint failed',1;
  IF toolbelt_core.SVF_IsCancellationRequested(@Execution)=1
   THROW 50001,N'Cooperative cancellation',1;
  WAITFOR DELAY '00:00:00.200';
  SET @Steps+=1;
 END;
 UPDATE dbo.TbxWorkerLedger SET Active=0 WHERE WorkItemId=@Id;
END;
GO
CREATE PROCEDURE dbo.USP_TbxWorkerWait @PayloadJson nvarchar(max) AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Id bigint=CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.work_item_id')),
 @Delay varchar(12)=JSON_VALUE(@PayloadJson,'$.delay');
 IF @Delay NOT IN('00:00:04','00:01:10') THROW 50010,N'Synthetic wait outside fixture',1;
 INSERT dbo.TbxWorkerLedger VALUES(@Id,'wait',JSON_VALUE(@PayloadJson,'$.marker'),
 toolbelt_core.SVF_CurrentExecutionId(),CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.claim_generation')),1);
 WAITFOR DELAY @Delay;
 UPDATE dbo.TbxWorkerLedger SET Active=0 WHERE WorkItemId=@Id;
END;
GO
CREATE PROCEDURE dbo.USP_TbxWorkerResultset AS
BEGIN
 SET NOCOUNT ON;
 SELECT CONVERT(int,1) AS SyntheticForbiddenResult;
END;
GO
CREATE PROCEDURE dbo.USP_TbxWorkerContextDrift AS
BEGIN
 SET NOCOUNT ON;
 INSERT dbo.TbxWorkerLedger VALUES(CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.work_item_id')),
 'context-drift',N'synthetic',toolbelt_core.SVF_CurrentExecutionId(),
 CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.claim_generation')),0);
 DECLARE @Wrong uniqueidentifier=NEWID();
 EXEC sys.sp_set_session_context @key=N'toolbelt.execution.id',@value=@Wrong;
END;
GO
CREATE PROCEDURE dbo.USP_TbxWorkerReadonlyMutation AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Protected uniqueidentifier=CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.execution_id')),
 @Wrong uniqueidentifier=NEWID();
 INSERT dbo.TbxWorkerLedger VALUES(CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.work_item_id')),
 'readonly-mutation',N'synthetic',@Protected,
 CONVERT(bigint,SESSION_CONTEXT(N'toolbelt.worker.claim_generation')),0);
 BEGIN TRY
  EXEC sys.sp_set_session_context @key=N'toolbelt.worker.execution_id',@value=@Wrong,@read_only=1;
  THROW 50003,N'Synthetic readonly identity guard failed',1;
 END TRY
 BEGIN CATCH
  IF CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.execution_id'))<>@Protected
   OR toolbelt_core.SVF_CurrentExecutionId()<>@Protected
   THROW 50003,N'Synthetic identity changed after rejected mutation',1;
  THROW;
 END CATCH;
END;
GO
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.worker.none',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxWorkerNone',@ParameterMode='NONE';
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.worker.json',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxWorkerJson',@ParameterMode='JSON_PAYLOAD',@PayloadContractJson=N'{"type":"object"}';
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.worker.terminal',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxWorkerTerminal',@ParameterMode='NONE';
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.worker.retry',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxWorkerRetry',@ParameterMode='NONE',@IsIdempotent=1;
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.worker.dead',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxWorkerAlwaysTransient',@ParameterMode='NONE',@IsIdempotent=1;
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.worker.watchdog',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxWorkerCancellation',@ParameterMode='NONE',@DefaultTimeoutSeconds=1;
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.worker.cancel',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxWorkerCancellation',@ParameterMode='NONE',@DefaultTimeoutSeconds=300;
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.worker.wait',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxWorkerWait',@ParameterMode='JSON_PAYLOAD',@PayloadContractJson=N'{"type":"object"}',@DefaultTimeoutSeconds=300;
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.worker.unsupported',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxWorkerNone',@ParameterMode='NONE';
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.worker.resultset',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxWorkerResultset',@ParameterMode='NONE';
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.worker.context-drift',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxWorkerContextDrift',@ParameterMode='NONE';
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.worker.readonly-mutation',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxWorkerReadonlyMutation',@ParameterMode='NONE';
GO
