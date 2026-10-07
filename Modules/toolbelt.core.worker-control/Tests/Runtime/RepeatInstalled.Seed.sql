:On Error exit
SET NOCOUNT ON;
-- Terminale History ist Testdatenaufbau, kein Handlercommit-/Rollbacknachweis.
-- Reine Sessionguards stehen vor den Katalog-/Historyreads.
IF @@TRANCOUNT<>0 THROW 54960,N'Controlrepeat verlangt frisch installierten Control1.0.',3;
IF XACT_STATE()<>0 THROW 54960,N'Controlrepeat verlangt frisch installierten Control1.0.',3;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0')
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration)
 THROW 54960,N'Controlrepeat verlangt frisch installierten Control1.0.',3;
DECLARE @Worker uniqueidentifier='00000000-0000-0000-0000-000000006001',@Now datetime2(7)=SYSUTCDATETIME();
INSERT toolbelt_core.WorkerRegistration(WorkerId,WorkerGeneration,WorkerToken,OwnerPrincipalId,ProviderKind,State,AdmissionPaused,Capacity,RunMode,LastHeartbeatAtUtc,HeartbeatSeconds,UnreachableSeconds)
 VALUES(@Worker,1,'00000000-0000-0000-0000-000000006011',DATABASE_PRINCIPAL_ID(),'EXTERNAL','CLOSED',1,2,'BOUNDED',@Now,15,60),
       (@Worker,2,'00000000-0000-0000-0000-000000006012',DATABASE_PRINCIPAL_ID(),'EXTERNAL','PAUSED',1,3,'CONTINUOUS',@Now,15,60);
;WITH items AS(SELECT TOP(3) WorkItemId,ClaimGeneration,ClaimToken,ROW_NUMBER() OVER(ORDER BY WorkItemId) Ordinal FROM toolbelt_core.WorkItem WHERE Status='COMPLETED' ORDER BY WorkItemId)
INSERT toolbelt_core.WorkerSlotReservation(SlotReservationId,WorkerId,WorkerGeneration,WorkItemId,ClaimGeneration,ClaimToken,ExecutionId,State,IsOccupied,AttemptNonce,BoundPrincipalId,CreatedAtUtc,EndedAtUtc)
 SELECT CONVERT(uniqueidentifier,CASE Ordinal WHEN 1 THEN '00000000-0000-0000-0000-000000006021' WHEN 2 THEN '00000000-0000-0000-0000-000000006022' ELSE '00000000-0000-0000-0000-000000006023' END),
 @Worker,1,WorkItemId,ClaimGeneration,ClaimToken,
 CONVERT(uniqueidentifier,CASE Ordinal WHEN 1 THEN '00000000-0000-0000-0000-000000006031' WHEN 2 THEN '00000000-0000-0000-0000-000000006032' ELSE '00000000-0000-0000-0000-000000006033' END),
 CASE Ordinal WHEN 1 THEN 'COMMITTED' WHEN 2 THEN 'ROLLED_BACK' ELSE 'CLOSED' END,0,
 '00000000-0000-0000-0000-000000006041',DATABASE_PRINCIPAL_ID(),@Now,@Now FROM items;
IF (SELECT COUNT(*) FROM toolbelt_core.WorkerSlotReservation)<>3 THROW 54960,N'Drei synthetische Terminalhistories fehlen.',4;
INSERT toolbelt_core.WorkerExecutionDisposition(WorkItemId,SlotReservationId,IsHeld,StopStatus)
 SELECT WorkItemId,SlotReservationId,0,CASE State WHEN 'COMMITTED' THEN 'ALREADY_COMMITTED' ELSE 'NONE' END FROM toolbelt_core.WorkerSlotReservation;
INSERT toolbelt_core.WorkerExecutionCommitWitness(SlotReservationId,AttemptNonce,ExecutionId,ClaimGeneration,RecordedAtUtc)
 SELECT SlotReservationId,AttemptNonce,ExecutionId,ClaimGeneration,@Now FROM toolbelt_core.WorkerSlotReservation WHERE State='COMMITTED';
CREATE TABLE #tbx_ControlRepeatObjects(ObjectId int NOT NULL PRIMARY KEY,ObjectName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,ObjectType char(2) NOT NULL);
INSERT #tbx_ControlRepeatObjects
 SELECT o.object_id,o.name,o.type FROM sys.objects o JOIN sys.extended_properties ep ON ep.class=1 AND ep.major_id=o.object_id AND ep.minor_id=0 AND ep.name=N'Toolbelt.ModuleId'
 WHERE o.schema_id=SCHEMA_ID(N'toolbelt_core') AND CONVERT(nvarchar(256),ep.value) IN(N'toolbelt.core.work-queue',N'toolbelt.core.worker-control',N'toolbelt.core.work-type') AND o.type IN('U','P','V');
IF (SELECT COUNT(*) FROM #tbx_ControlRepeatObjects WHERE ObjectType='U')<>10
 THROW 54960,N'Repeat erwartet alle zehn persistenten Tabellen.',5;
GO
