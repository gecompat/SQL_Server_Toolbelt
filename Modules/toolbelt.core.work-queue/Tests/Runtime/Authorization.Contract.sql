SET QUOTED_IDENTIFIER ON;
-- Eigene disposable Testdatenbank; prüfen echten Callertoken statt bloßer Sicht.
SET NOCOUNT ON;
GO
CREATE OR ALTER PROCEDURE dbo.USP_SecurityQueueNoop AS RETURN 0;
GO
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='security.queue',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_SecurityQueueNoop';
CREATE USER SecurityQueueActor WITHOUT LOGIN;
GRANT EXECUTE ON toolbelt_core.USP_EnqueueWork TO SecurityQueueActor;
GRANT EXECUTE ON toolbelt_core.USP_EnqueueWorkWithPolicy TO SecurityQueueActor;
GRANT EXECUTE ON toolbelt_core.USP_EnqueueBarrierWork TO SecurityQueueActor;
GRANT EXECUTE ON toolbelt_core.USP_ClaimWork TO SecurityQueueActor;
GRANT EXECUTE ON toolbelt_core.USP_PrepareResultTable TO SecurityQueueActor;
GRANT VIEW DEFINITION ON dbo.USP_SecurityQueueNoop TO SecurityQueueActor;
GO
EXECUTE AS USER='SecurityQueueActor';
BEGIN TRY
 EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='security.queue';
 REVERT; THROW 52991,N'Enqueue ohne Policy wurde erlaubt.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>51998 BEGIN REVERT; THROW; END;
END CATCH;
REVERT;
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkTypeId=(SELECT WorkTypeId FROM toolbelt_core.WorkType WHERE WorkTypeName='security.queue'))
 THROW 52991,N'Abgewiesenes Enqueue hat Arbeit erzeugt.',1;
EXEC toolbelt_core.USP_SetWorkTypePermission 'security.queue',N'SecurityQueueActor','ENQUEUE','ALLOW';
EXEC toolbelt_core.USP_SetWorkTypePermission 'security.queue',N'SecurityQueueActor','CLAIM','ALLOW';
EXECUTE AS USER='SecurityQueueActor';
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='security.queue';
REVERT;
CREATE TABLE #SecurityClaim
(WorkItemId bigint,WorkTypeName varchar(128),PayloadJson nvarchar(max),ClaimToken uniqueidentifier,
 ClaimedAtUtc datetime2(7),ClaimGeneration bigint,LeaseUntilUtc datetime2(7),LastHeartbeatAtUtc datetime2(7));
EXECUTE AS USER='SecurityQueueActor';
EXEC toolbelt_core.USP_ClaimWork @ResultTable=N'#SecurityClaim';
REVERT;
IF EXISTS(SELECT 1 FROM #SecurityClaim) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE Status='CLAIMED' AND WorkTypeId=(SELECT WorkTypeId FROM toolbelt_core.WorkType WHERE WorkTypeName='security.queue'))
 THROW 52991,N'Sichtbarer, nicht ausführbarer Handler wurde geclaimt.',1;
GRANT EXECUTE ON dbo.USP_SecurityQueueNoop TO SecurityQueueActor;
EXECUTE AS USER='SecurityQueueActor';
EXEC toolbelt_core.USP_ClaimWork @ResultTable=N'#SecurityClaim';
REVERT;
IF (SELECT COUNT(*) FROM #SecurityClaim)<>1
 THROW 52991,N'Autorisierter Worker hat keine Arbeit erhalten.',1;
DELETE toolbelt_core.WorkItem WHERE WorkTypeId=(SELECT WorkTypeId FROM toolbelt_core.WorkType WHERE WorkTypeName='security.queue');
DELETE #SecurityClaim;
-- DENY muss auch vor einer Idempotency-Auskunft greifen.
EXECUTE AS USER='SecurityQueueActor';
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @WorkTypeName='security.queue',@IdempotencyKey='security.key';
REVERT;
EXEC toolbelt_core.USP_SetWorkTypePermission 'security.queue',N'SecurityQueueActor','ENQUEUE','DENY';
EXECUTE AS USER='SecurityQueueActor';
BEGIN TRY
 EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @WorkTypeName='security.queue',@IdempotencyKey='security.key';
 REVERT; THROW 52991,N'Idempotency-Auskunft umging DENY.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>51998 BEGIN REVERT; THROW; END;
END CATCH;
REVERT;
BEGIN TRANSACTION;
BEGIN TRY
 EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @WorkTypeName='security.queue',@ExecutionMode='DRAIN_BARRIER';
 ROLLBACK; THROW 52991,N'Barrier in Callertransaktion wurde erlaubt.',1;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>51997 BEGIN IF @@TRANCOUNT>0 ROLLBACK; THROW; END;
END CATCH;
IF @@TRANCOUNT<>1 BEGIN IF @@TRANCOUNT>0 ROLLBACK; THROW 52991,N'Barrierabweisung hat Callertransaktion verändert.',1; END;
ROLLBACK;
IF (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE WorkTypeId=(SELECT WorkTypeId FROM toolbelt_core.WorkType WHERE WorkTypeName='security.queue'))<>1
 THROW 52991,N'Abgewiesene Aufrufe haben Queue verändert.',1;
DELETE toolbelt_core.WorkItem WHERE WorkTypeId=(SELECT WorkTypeId FROM toolbelt_core.WorkType WHERE WorkTypeName='security.queue');
DELETE toolbelt_core.WorkTypePermission WHERE WorkTypeId=(SELECT WorkTypeId FROM toolbelt_core.WorkType WHERE WorkTypeName='security.queue');
DELETE toolbelt_core.WorkType WHERE WorkTypeName='security.queue';
DROP USER SecurityQueueActor;
DROP PROCEDURE dbo.USP_SecurityQueueNoop;
DROP TABLE #SecurityClaim;
PRINT N'Queue-Autorisierungsvertrag: erfolgreich';
GO
