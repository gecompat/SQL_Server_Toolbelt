:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT OFF;
-- Nach genuine2.0→2.1 und zwei Queue-only-Repeats, ausschließlich eigene
-- synthetische Daten. Claims fachlich abschließen, Control niemals abbauen.
-- Sitzungszustand vor jeder Tabellenabfrage separat prüfen.
IF @@TRANCOUNT<>0 THROW 54960,N'Controlrepeat-Setup verlangt neutralen Queue-only-Zustand.',1;
IF XACT_STATE()<>0 THROW 54960,N'Controlrepeat-Setup verlangt neutralen Queue-only-Zustand.',1;
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.Version')
 OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueManagedGate WHERE GateId=1 AND ManagedEnabled=0 AND PendingReservationId IS NULL)
 THROW 54960,N'Controlrepeat-Setup verlangt neutralen Queue-only-Zustand.',1;
DECLARE @Item bigint,@Token uniqueidentifier;
CREATE TABLE #ControlRepeatCompletion(Dummy int NULL);
DECLARE claims CURSOR LOCAL FAST_FORWARD FOR SELECT WorkItemId,ClaimToken FROM toolbelt_core.WorkItem WHERE Status='CLAIMED' ORDER BY WorkItemId;
OPEN claims;FETCH NEXT FROM claims INTO @Item,@Token;
WHILE @@FETCH_STATUS=0 BEGIN
 EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@Item,@ClaimToken=@Token,@ResultTable=N'#ControlRepeatCompletion';
 FETCH NEXT FROM claims INTO @Item,@Token;
END;
CLOSE claims;DEALLOCATE claims;
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE Status='CLAIMED' OR ManagedHold=1)
 THROW 54960,N'Synthetische Claims wurden nicht fachlich abgeschlossen.',2;
GO
