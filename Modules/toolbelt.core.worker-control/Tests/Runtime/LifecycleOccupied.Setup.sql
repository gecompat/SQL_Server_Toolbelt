:On Error exit
SET NOCOUNT ON;SET XACT_ABORT OFF;
-- Nach erfolgreicher Basicfixture auf derselben isolierten Connection, keine Actors.
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1) THROW 54950,N'Lifecyclevorbereitung verlangt keine aktiven Verbraucher.',1;
DECLARE @Item bigint,@Hold binary(8),@Worker uniqueidentifier,@Generation bigint,@Token uniqueidentifier,@Config binary(8);
SELECT TOP(1) @Item=d.WorkItemId,@Hold=d.HoldVersion,@Worker=r.WorkerId FROM toolbelt_core.WorkerExecutionDisposition d JOIN toolbelt_core.WorkerSlotReservation r ON r.SlotReservationId=d.SlotReservationId WHERE d.IsHeld=1 AND r.State='ROLLED_BACK' AND r.IsOccupied=0 ORDER BY d.WorkItemId;
IF @Item IS NULL THROW 54950,N'Bewiesene synthetische Holdhistory fehlt.',2;
SELECT TOP(1) @Generation=WorkerGeneration,@Token=WorkerToken FROM toolbelt_core.WorkerRegistration WHERE WorkerId=@Worker ORDER BY WorkerGeneration DESC;
CREATE TABLE #LifecycleResult(Dummy int NULL);CREATE TABLE #LifecycleClaim(Dummy int NULL);
EXEC toolbelt_core.USP_ReleaseHeldWork @WorkItemId=@Item,@ExpectedHoldVersion=@Hold,@ResultTable=N'#LifecycleResult';
SET @Config=(SELECT ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1);
EXEC toolbelt_core.USP_SetWorkerState @WorkerId=@Worker,@WorkerGeneration=@Generation,@RequestedState='ACTIVE',@ExpectedConfigVersion=@Config,@ResultTable=N'#LifecycleResult';
SET @Config=(SELECT ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1);
EXEC toolbelt_core.USP_SetWorkerConcurrency @MaxConcurrentExecutions=1,@ExpectedConfigVersion=@Config,@ResultTable=N'#LifecycleResult';
EXEC toolbelt_core.USP_HeartbeatWorker @WorkerId=@Worker,@WorkerGeneration=@Generation,@WorkerToken=@Token;
EXEC toolbelt_core.USP_ClaimWorkerWork @WorkerId=@Worker,@WorkerGeneration=@Generation,@WorkerToken=@Token,@ResultTable=N'#LifecycleClaim';
IF (SELECT COUNT(*) FROM #LifecycleClaim)<>1 OR NOT EXISTS(SELECT 1 FROM #LifecycleClaim WHERE WorkItemId=@Item) THROW 54950,N'Actual reservierter Lifecycleclaim fehlt.',3;
-- Dann Lifecycle.Snapshot.sql; tatsächliches Deploy muss54242/1 liefern,
-- tatsächliches Uninstall(Confirm1/AllowDataLoss1) muss54246/2 liefern.
