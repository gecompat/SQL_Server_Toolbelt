:On Error exit
SET NOCOUNT ON;SET XACT_ABORT OFF;
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1) THROW 54952,N'Consumer-Test verlangt quieszenten Zustand.',1;
DECLARE @Item bigint,@Hold binary(8),@Config binary(8);
DECLARE holds CURSOR LOCAL FAST_FORWARD FOR SELECT WorkItemId,HoldVersion FROM toolbelt_core.WorkerExecutionDisposition WHERE IsHeld=1;
OPEN holds;FETCH NEXT FROM holds INTO @Item,@Hold;
WHILE @@FETCH_STATUS=0 BEGIN EXEC toolbelt_core.USP_ReleaseHeldWork @WorkItemId=@Item,@ExpectedHoldVersion=@Hold,@ResultTable=N'#LifecycleResult';FETCH NEXT FROM holds INTO @Item,@Hold;END;
CLOSE holds;DEALLOCATE holds;
SET @Config=(SELECT ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1);
EXEC toolbelt_core.USP_SetWorkerConcurrency @MaxConcurrentExecutions=0,@ExpectedConfigVersion=@Config,@ResultTable=N'#LifecycleResult';
SET @Config=(SELECT ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1);
EXEC toolbelt_core.USP_DisableManagedWorkers @ExpectedConfigVersion=@Config,@ResultTable=N'#LifecycleResult';
GO
CREATE VIEW dbo.VW_TbxWorkerForeignConsumer AS SELECT WorkerId,WorkerGeneration FROM toolbelt_core.VW_WorkerStatus;
GO
-- Snapshot erneuern; tatsächliches Deploy UND Uninstall(Confirm1/AllowDataLoss1)
-- müssen54243/1 liefern: Confirm darf sichtbare fremde SQL-Abhängigkeit nicht übergehen.
