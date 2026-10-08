-- Privater Testprototyp: genau ein bereits verglichener eigener Legacyclaim, keine Leaseänderung.
SET NOCOUNT ON;
IF @@TRANCOUNT<>0 THROW 54996,N'Der Upgrade-Repeat verlangt eine neutrale Sitzung.',1;
IF XACT_STATE()<>0 THROW 54996,N'Der Upgrade-Repeat verlangt eine neutrale Sitzung.',1;
IF (@@OPTIONS&2)<>0 THROW 54996,N'Der Upgrade-Repeat verlangt eine neutrale Sitzung.',1;
IF @@LOCK_TIMEOUT<>-1 THROW 54996,N'Der Upgrade-Repeat verlangt eine neutrale Sitzung.',1;
-- Genau ein vorhandener eigener Payloadzeuge, unabhängig vom veränderlichen Status.
DECLARE @OwnWorkItemId bigint;
IF (SELECT COUNT(*) FROM toolbelt_core.WorkItem w JOIN toolbelt_core.WorkType t ON t.WorkTypeId=w.WorkTypeId WHERE
 CONVERT(varbinary(max),t.WorkTypeName)=CONVERT(varbinary(max),'test.export.upgrade20') AND
 CONVERT(varbinary(max),w.PayloadJson)=CONVERT(varbinary(max),N'{"synthetic":"claimed – 漢字 "}'))<>1
 THROW 54996,N'Der einzelne eigene Legacyclaim ist nicht eindeutig gebunden.',2;
SELECT @OwnWorkItemId=WorkItemId FROM toolbelt_core.WorkItem w JOIN toolbelt_core.WorkType t ON t.WorkTypeId=w.WorkTypeId WHERE
 CONVERT(varbinary(max),t.WorkTypeName)=CONVERT(varbinary(max),'test.export.upgrade20') AND
 CONVERT(varbinary(max),w.PayloadJson)=CONVERT(varbinary(max),N'{"synthetic":"claimed – 漢字 "}');
DECLARE @OwnClaimToken uniqueidentifier,@OwnRowVersion binary(8),@Before datetime2(7)=SYSUTCDATETIME();
SELECT @OwnClaimToken=ClaimToken,@OwnRowVersion=CONVERT(binary(8),RowVersion)
 FROM toolbelt_core.WorkItem WHERE WorkItemId=@OwnWorkItemId;
IF (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='CLAIMED')<>1
 OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@OwnWorkItemId AND Status='CLAIMED'
 AND ClaimToken IS NOT NULL AND ClaimGeneration>0 AND LeaseUntilUtc>@Before
 AND ManagedReservationId IS NULL AND ManagedHold=0 AND ManagedCompletionNonce IS NULL
 AND CompletedAtUtc IS NULL AND CompletedBy IS NULL)
 THROW 54996,N'Der eigene gültige unmanaged Legacyclaim fehlt.',3;
CREATE TABLE #ExportUpgradeRepeatCompletion(Dummy int NULL);
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@OwnWorkItemId,@ClaimToken=@OwnClaimToken,
 @ResultTable=N'#ExportUpgradeRepeatCompletion',@Debug=0,@Hilfe=0;
DECLARE @After datetime2(7)=SYSUTCDATETIME();
IF (SELECT COUNT(*) FROM #ExportUpgradeRepeatCompletion)<>1
 OR NOT EXISTS(SELECT 1 FROM #ExportUpgradeRepeatCompletion WHERE WorkItemId=@OwnWorkItemId AND Status='COMPLETED')
 OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@OwnWorkItemId AND Status='COMPLETED'
 AND CompletedAtUtc>=@Before AND CompletedAtUtc<=@After
 AND CONVERT(varbinary(max),CompletedBy)=CONVERT(varbinary(max),ORIGINAL_LOGIN())
 AND CONVERT(binary(8),RowVersion)<>@OwnRowVersion AND ClaimToken=@OwnClaimToken)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE Status='CLAIMED')
 THROW 54996,N'Der einzige eigene Abschluss besitzt nicht den erwarteten Status-, Audit- und Rowversionübergang.',4;
DROP TABLE #ExportUpgradeRepeatCompletion;
IF @@TRANCOUNT<>0 THROW 54996,N'Der eigene Abschluss hinterließ eine Transaktion.',5;
IF XACT_STATE()<>0 THROW 54996,N'Der eigene Abschluss hinterließ eine Transaktion.',5;
IF (@@OPTIONS&2)<>0 THROW 54996,N'Der eigene Abschluss hinterließ keine neutrale Sitzung.',5;
IF @@LOCK_TIMEOUT<>-1 THROW 54996,N'Der eigene Abschluss hinterließ keine neutrale Sitzung.',5;
