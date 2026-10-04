:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT OFF;
-- Tatsächlich installierter Originalstand aus gepinntem Commit
-- 62e7b06588b28c45c58f7ec335e4e5c45f120e3e; keine Versionmarker-Simulation.
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.work-queue.Version' AND CONVERT(nvarchar(64),value)=N'2.0.0')
 OR COL_LENGTH(N'toolbelt_core.WorkItem',N'ManagedHold') IS NOT NULL OR OBJECT_ID(N'toolbelt_core.WorkQueueManagedGate') IS NOT NULL OR OBJECT_ID(N'toolbelt_core.USP_ClaimWorkCore') IS NOT NULL THROW 54920,N'Genuine Queue2.0-Vorzustand fehlt.',1;
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem) THROW 54920,N'Upgradefixture verlangt eine leere isolierte Queue.',2;
GO
CREATE OR ALTER PROCEDURE dbo.USP_TbxQueueUpgradeJson @PayloadJson nvarchar(max) AS BEGIN SET NOCOUNT ON;END;
GO
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.queue.upgrade20',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxQueueUpgradeJson',@ParameterMode='JSON_PAYLOAD',@PayloadContractJson=N'{"type":"object"}';
CREATE TABLE #Upgrade20Status(Dummy int NULL);
CREATE TABLE #Upgrade20Claim(Dummy int NULL);
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.queue.upgrade20',@PayloadJson=N'{"synthetic":"completed – Ω"}',@ResultTable=N'#Upgrade20Status';
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.queue.upgrade20',@PayloadJson=N'{"synthetic":"claimed – 漢字"}',@ResultTable=N'#Upgrade20Status';
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.queue.upgrade20',@PayloadJson=N'{"synthetic":"queued – ä"}',@ResultTable=N'#Upgrade20Status';
-- Historisches Schedulerresultset nicht per INSERT EXEC als Claim interpretieren.
EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=86400,@ResultTable=N'#Upgrade20Claim';
DECLARE @First bigint=(SELECT WorkItemId FROM #Upgrade20Claim),@FirstToken uniqueidentifier=(SELECT ClaimToken FROM #Upgrade20Claim);
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@First,@ClaimToken=@FirstToken,@ResultTable=N'#Upgrade20Status';
EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=86400,@ResultTable=N'#Upgrade20Claim';
IF (SELECT COUNT(*) FROM toolbelt_core.WorkItem)<>3 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='QUEUED')<>1 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='CLAIMED')<>1 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='COMPLETED')<>1 THROW 54921,N'Die drei Original-API-Zustände fehlen.',1;
SELECT [WorkItemId],[WorkTypeId],[PayloadJson],[Status],[EnqueuedAtUtc],[EnqueuedBy],[ClaimedAtUtc],[ClaimedBy],[ClaimToken],[ClaimGeneration],[LeaseDurationSeconds],[LeaseUntilUtc],[LastHeartbeatAtUtc],[RecoveryCount],[LastRecoveredAtUtc],[LastRecoveredBy],[CompletedAtUtc],[CompletedBy],[FailedAtUtc],[FailedBy],[FailureCode],[FailureMessage],[RowVersion],[ExecutionGroup],[Priority],[ExecutionMode],[IdempotencyKey],[MaxAttempts],[RetryBaseDelaySeconds],[RetryMaxDelaySeconds],[RetryCycleNumber],[CycleAttemptCount],[NextAttemptAtUtc],[LastErrorCode],[LastErrorMessage],[LastRetryScheduledAtUtc],[LastRetryScheduledBy],[DeadLetteredAtUtc],[DeadLetteredBy],[LastRequeuedAtUtc],[LastRequeuedBy],[LastRequeueReason],[BarrierEpoch] INTO #Upgrade20Rows FROM toolbelt_core.WorkItem;
CREATE TABLE #Upgrade20Identity(IdentityCurrent decimal(38,0),IdentitySeed decimal(38,0),IdentityIncrement decimal(38,0));
INSERT #Upgrade20Identity VALUES(IDENT_CURRENT(N'toolbelt_core.WorkItem'),IDENT_SEED(N'toolbelt_core.WorkItem'),IDENT_INCR(N'toolbelt_core.WorkItem'));
-- Dieselbe Connection und lokale Temp-Snapshots bis Verify erhalten.
