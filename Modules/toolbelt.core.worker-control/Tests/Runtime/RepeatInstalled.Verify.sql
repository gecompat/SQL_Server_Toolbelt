:On Error exit
:r RepeatInstalled.Snapshot.sql
:r RepeatInstalled.Compare.sql
IF @@LOCK_TIMEOUT<>-1 THROW 54961,N'Erfolgreicher Repeat restaurierte den Standardsitzungs-Locktimeout nicht.',5;
IF (SELECT COUNT(DISTINCT TableName) FROM #tbx_ControlRepeatActualRows)<>10
 OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueManagedGate WHERE GateId=1 AND ManagedEnabled=0 AND PendingReservationId IS NULL)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE Status='CLAIMED' OR ManagedHold=1)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition WHERE IsHeld=1)
 THROW 54961,N'Repeat verlor quieszenten zehn-Tabellenzustand.',4;
GO
