-- Eigene genuine Queue2.0; Original-API-Zustände ohne neuen Callback und ohne Handlerdispatch.
SET NOCOUNT ON;
SET XACT_ABORT OFF;
IF @@TRANCOUNT<>0
 THROW 54990,N'Exportupgrade verlangt eine neutrale Session.',1;
IF XACT_STATE()<>0
 THROW 54990,N'Exportupgrade verlangt eine neutrale Session.',1;
IF (@@OPTIONS&2)<>0
 THROW 54990,N'Exportupgrade verlangt eine neutrale Session.',1;
IF @@LOCK_TIMEOUT<>-1
 THROW 54990,N'Exportupgrade verlangt eine neutrale Session.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.work-queue.Version' AND CONVERT(nvarchar(64),value)=N'2.0.0')
 OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE (class=0 AND name LIKE N'Toolbelt.Module.toolbelt.core.worker-control.%') OR (class=1 AND name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(256),value)=N'toolbelt.core.worker-control'))
 OR OBJECT_ID(N'toolbelt_core.WorkQueueManagedGate') IS NOT NULL OR OBJECT_ID(N'toolbelt_core.USP_ClaimWorkCore') IS NOT NULL
 OR COL_LENGTH(N'toolbelt_core.WorkItem',N'ManagedHold') IS NOT NULL
 OR EXISTS(SELECT 1 FROM sys.objects o WHERE o.schema_id=SCHEMA_ID(N'toolbelt_core') AND o.name IN(N'WorkerControlConfiguration',N'WorkerRegistration',N'WorkerSlotReservation',N'WorkerExecutionDisposition',N'WorkerExecutionCommitWitness',N'VW_WorkerStatus',N'VW_WorkerExecutionStatus',N'USP_BeginWorkerCompletion',N'USP_BeginWorkerTransactionWitness',N'USP_BindWorkerExecution',N'USP_ClaimWorkerWork',N'USP_CloseWorker',N'USP_DisableManagedWorkers',N'USP_EnableManagedWorkers',N'USP_FinalizeWorkerFailure',N'USP_HeartbeatWorker',N'USP_ReconcileWorkerExecution',N'USP_RecordWorkerCommit',N'USP_RecordWorkerRollback',N'USP_RecordWorkerUnknown',N'USP_RegisterWorker',N'USP_ReleaseHeldWork',N'USP_ReserveWorkerExecution',N'USP_SetWorkerCapacity',N'USP_SetWorkerConcurrency',N'USP_SetWorkerIntervals',N'USP_SetWorkerState',N'USP_StopWorkerExecution',N'USP_StopWorkers'))
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueBarrierBlocker)
 THROW 54990,N'Genuine2.0 ohne Control und mit leerer eigener Queue fehlt.',2;
IF EXISTS(SELECT 1 FROM(VALUES(N'WorkItem'),(N'WorkQueueScheduler'),(N'WorkQueueBarrierBlocker'))e(TableName)
 WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(e.TableName),N'U') AND p.minor_id=0 AND p.name=N'Toolbelt.ModuleId' AND SQL_VARIANT_PROPERTY(p.value,'BaseType')='nvarchar' AND CONVERT(nvarchar(256),p.value)=N'toolbelt.core.work-queue')
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(e.TableName),N'U') AND p.minor_id=0 AND p.name=N'Toolbelt.ModuleVersion' AND SQL_VARIANT_PROPERTY(p.value,'BaseType')='nvarchar' AND CONVERT(nvarchar(64),p.value)=N'2.0.0'))
 THROW 54990,N'Die ursprünglichen typisierten Queue-Tabellenmarker fehlen.',7;
-- Kanonischer vorhandener JSON-Handler erfüllt den Registrierungsvertrag; er wird niemals aufgerufen.
DECLARE @Handler int=OBJECT_ID(N'toolbelt_core.USP_WriteEventInternal',N'P');
IF @Handler IS NULL OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=@Handler)<>1
 OR NOT EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=@Handler AND parameter_id=1 AND name=N'@PayloadJson' AND system_type_id=231 AND max_length=-1 AND is_output=0)
 THROW 54990,N'Der vorhandene JSON-Payload-Handler besitzt nicht den erwarteten Vertrag.',3;
CREATE TABLE #tbx_ExportUpgradeStatus(Dummy int NULL);
CREATE TABLE #tbx_ExportUpgradeClaim(Dummy int NULL);
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.export.upgrade20',@HandlerSchema=N'toolbelt_core',@HandlerProcedure=N'USP_WriteEventInternal',@ParameterMode='JSON_PAYLOAD',@PayloadContractJson=N'{"type":"object"}';
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.export.upgrade20',@PayloadJson=N'{"synthetic":"completed – Ω "}',@ResultTable=N'#tbx_ExportUpgradeStatus';
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.export.upgrade20',@PayloadJson=N'{"synthetic":"claimed – 漢字 "}',@ResultTable=N'#tbx_ExportUpgradeStatus';
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.export.upgrade20',@PayloadJson=N'{"synthetic":"queued – ä "}',@ResultTable=N'#tbx_ExportUpgradeStatus';
EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=86400,@ResultTable=N'#tbx_ExportUpgradeClaim';
DECLARE @First bigint=(SELECT WorkItemId FROM #tbx_ExportUpgradeClaim),@Token uniqueidentifier=(SELECT ClaimToken FROM #tbx_ExportUpgradeClaim);
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@First,@ClaimToken=@Token,@ResultTable=N'#tbx_ExportUpgradeStatus';
EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=86400,@ResultTable=N'#tbx_ExportUpgradeClaim';
IF (SELECT COUNT(*) FROM toolbelt_core.WorkItem)<>3 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='COMPLETED')<>1
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='CLAIMED')<>1 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='QUEUED')<>1
 THROW 54990,N'Die drei Original-API-Zustände fehlen.',4;
DECLARE @Now datetime2(7)='2026-01-02T03:04:05.1234567';
INSERT toolbelt_core.ExecutionCancellation(ExecutionId,RequestedAtUtc,RequestedBy,CancellationReason)
VALUES('00000000-0000-0000-0000-000000008101',@Now,N'Synthetic requester ä ',NULL),
 ('00000000-0000-0000-0000-000000008102','2026-02-03T04:05:06.0000001',N'Synthetic requester 中 ',N''),
 ('00000000-0000-0000-0000-000000008103','2026-03-04T05:06:07.9999999',N'Synthetic requester ',N'Unicode ä 中  ');
UPDATE toolbelt_core.ExecutionCancellation SET CancellationReason=CancellationReason WHERE ExecutionId='00000000-0000-0000-0000-000000008103';
INSERT toolbelt_core.SecondSessionProvider(ProviderName,LinkedServerName,IsEnabled,CreatedAtUtc,CreatedBy,ModifiedAtUtc,ModifiedBy)
 VALUES('loopback',N'localhost',0,@Now,N'Synthetic creator ä ','2026-02-03T04:05:06.0000001',N'Synthetic modifier 中 ');
UPDATE toolbelt_core.SecondSessionProvider SET IsEnabled=0 WHERE ProviderName='loopback';
INSERT toolbelt_file.FileContentRootAllowlist(RootPath,Description,IsActive,CreatedAt)
 VALUES(N'/synthetic/export/active',N'Active root',1,'2026-01-02T03:04:05'),
 (N'/synthetic/export/inactive',NULL,0,'2026-02-03T04:05:06'),
 (N'/synthetic/export/Unicode-ä-中',N'Unicode ä 中 ',1,'2026-03-04T05:06:07'),
 (N'/synthetic/export/trailing ',N'',0,'2026-04-05T06:07:08');
INSERT toolbelt_file.FileContentRootAllowlist(RootPath) VALUES(N'/synthetic/export/deleted');
DELETE toolbelt_file.FileContentRootAllowlist WHERE RootPath=N'/synthetic/export/deleted';
INSERT toolbelt_core.EventLog(OccurredAtUtc,RecordedAtUtc,EventName,EventLevel,Category,Message,DataJson,ExecutionId,CorrelationId,Actor,Tenant,SourceDatabaseName,SourceSchemaName,SourceObjectName,CallerSessionId,CallerXactState,CallerTransactionCount,RemoteSessionId,ErrorNumber,ErrorSeverity,ErrorState,ErrorProcedure,ErrorLine)
VALUES(@Now,'2026-01-02T03:04:05.1234568','test.export.null','INFO',NULL,NULL,NULL,'00000000-0000-0000-0000-000000008201','00000000-0000-0000-0000-000000008211',NULL,NULL,N'Contoso',NULL,NULL,1,0,0,2,NULL,NULL,NULL,NULL,NULL),
 ('2026-02-03T04:05:06.0000001','2026-02-03T04:05:06.0000002','test.export.unicode','CRITICAL','synthetic ',N'Unicode ä 中 ',N'{"text":"ä 中 "}','00000000-0000-0000-0000-000000008202','00000000-0000-0000-0000-000000008212',N'Actor ä ',N'Tenant 中 ',N'Fabrikam ',N'dbo ',N'Object 中 ',3,-1,2,4,50000,25,255,N'USP_Synthetic ',99),
 ('2026-03-04T05:06:07.9999999','2026-03-04T05:06:08.0000000','test.export.empty','DEBUG','',N'',N'{}','00000000-0000-0000-0000-000000008203','00000000-0000-0000-0000-000000008213',N'',N'',N'AdventureWorks',N'',N'',5,1,1,6,0,0,0,N'',1);
INSERT toolbelt_core.EventLog(OccurredAtUtc,EventName,EventLevel,ExecutionId,CorrelationId,SourceDatabaseName,CallerSessionId,CallerXactState,CallerTransactionCount,RemoteSessionId)
 VALUES(@Now,'test.export.deleted','INFO','00000000-0000-0000-0000-000000008204','00000000-0000-0000-0000-000000008214',N'Contoso',7,0,0,8);
DELETE toolbelt_core.EventLog WHERE EventName='test.export.deleted';

-- Acht alte Tabellen erhalten eigene typisierte Tabellen-/Spaltenannotation und Beschreibungszeugen.
DECLARE @Schema sysname,@Table sysname,@Column sysname,@Id int;
DECLARE annotations CURSOR LOCAL FAST_FORWARD FOR
 SELECT s.name,t.name,MIN(c.name) FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id
 JOIN sys.columns c ON c.object_id=t.object_id AND c.is_identity=0 AND c.system_type_id<>189
 WHERE (s.name=N'toolbelt_core' AND t.name IN(N'WorkType',N'WorkItem',N'WorkQueueScheduler',N'WorkQueueBarrierBlocker',N'ExecutionCancellation',N'SecondSessionProvider',N'EventLog'))
 OR (s.name=N'toolbelt_file' AND t.name=N'FileContentRootAllowlist') GROUP BY s.name,t.name;
OPEN annotations;FETCH NEXT FROM annotations INTO @Schema,@Table,@Column;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @Id=OBJECT_ID(QUOTENAME(@Schema)+N'.'+QUOTENAME(@Table));
 IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@Id AND
 (name=N'Toolbelt.Test.ExportUpgrade' OR (name=N'MS_Description' AND minor_id IN(0,COLUMNPROPERTY(@Id,@Column,'ColumnId')) AND NOT(@Schema=N'toolbelt_file' AND @Table=N'FileContentRootAllowlist' AND minor_id=0))))
 THROW 54990,N'Die eigene Upgradeannotation ist bereits belegt.',5;
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Test.ExportUpgrade',@value=271828,@level0type=N'SCHEMA',@level0name=@Schema,@level1type=N'TABLE',@level1name=@Table;
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Test.ExportUpgrade',@value=N'Synthetic legacy column 中 ',@level0type=N'SCHEMA',@level0name=@Schema,@level1type=N'TABLE',@level1name=@Table,@level2type=N'COLUMN',@level2name=@Column;
 IF NOT(@Schema=N'toolbelt_file' AND @Table=N'FileContentRootAllowlist')
 EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Synthetic legacy table ä ',@level0type=N'SCHEMA',@level0name=@Schema,@level1type=N'TABLE',@level1name=@Table;
 EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Synthetic legacy column 中 ',@level0type=N'SCHEMA',@level0name=@Schema,@level1type=N'TABLE',@level1name=@Table,@level2type=N'COLUMN',@level2name=@Column;
 FETCH NEXT FROM annotations INTO @Schema,@Table,@Column;
END;
CLOSE annotations;DEALLOCATE annotations;
DROP TABLE #tbx_ExportUpgradeClaim;
DROP TABLE #tbx_ExportUpgradeStatus;
IF @@TRANCOUNT<>0 THROW 54990,N'Das eigene Upgradesetup hinterließ eine Transaktion.',6;
IF XACT_STATE()<>0 THROW 54990,N'Das eigene Upgradesetup hinterließ eine Transaktion.',6;
