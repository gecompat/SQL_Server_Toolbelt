:On Error exit
SET NOCOUNT ON;SET XACT_ABORT OFF;
DECLARE @Slot uniqueidentifier=(SELECT SlotReservationId FROM #LifecycleClaim),@Gen bigint=(SELECT ClaimGeneration FROM #LifecycleClaim),@Hold binary(8);
EXEC toolbelt_core.USP_StopWorkerExecution @SlotReservationId=@Slot,@ExpectedClaimGeneration=@Gen,@ResultTable=N'#LifecycleResult';
SET @Hold=(SELECT HoldVersion FROM toolbelt_core.WorkerExecutionDisposition WHERE SlotReservationId=@Slot);
EXEC toolbelt_core.USP_ReconcileWorkerExecution @SlotReservationId=@Slot,@ExpectedHoldVersion=@Hold,@ResultTable=N'#LifecycleResult';
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1) OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition WHERE IsHeld=1) THROW 54951,N'Actual vorDispatch bewiesener Holdzustand fehlt.',1;
-- Snapshot erneuern; Deploy54242/1, Uninstall54246/2. Kein Handlerrollback simuliert.
