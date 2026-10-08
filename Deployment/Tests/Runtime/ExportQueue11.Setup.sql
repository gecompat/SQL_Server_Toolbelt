-- Private synthetische Genuine1.1-Upgradefixture; keine Produktobjekte oder Cleanup.
SET NOCOUNT ON;
IF @InstallMode IS NULL OR CONVERT(varbinary(max),@InstallMode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central')) THROW 55010,N'EXPORT_QUEUE11_MODE',1;
IF @@TRANCOUNT<>0 THROW 55010,N'EXPORT_QUEUE11_SESSION',1;
IF XACT_STATE()<>0 THROW 55010,N'EXPORT_QUEUE11_SESSION',1;
IF (@@OPTIONS&2)<>0 THROW 55010,N'EXPORT_QUEUE11_SESSION',1;
IF @@LOCK_TIMEOUT<>-1 THROW 55010,N'EXPORT_QUEUE11_SESSION',1;
SET XACT_ABORT OFF;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.core.work-queue.Version' AND SQL_VARIANT_PROPERTY(value,'BaseType')='nvarchar' AND CONVERT(varbinary(max),CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),N'1.1.0'))
 OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.toolbelt.core.worker-control.%')
 OR (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID(N'toolbelt_core.WorkItem',N'U'))<>23
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem)
 OR EXISTS(SELECT 1 FROM toolbelt_core.ExecutionCancellation)
 OR EXISTS(SELECT 1 FROM toolbelt_core.SecondSessionProvider)
 OR EXISTS(SELECT 1 FROM toolbelt_core.EventLog)
 OR EXISTS(SELECT 1 FROM toolbelt_file.FileContentRootAllowlist)
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkType)<>1
 OR EXISTS(SELECT 1 FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_core') AND name IN(N'WorkQueueScheduler',N'WorkQueueBarrierBlocker',N'WorkQueueManagedGate',N'WorkerControlConfiguration',N'WorkerRegistration',N'WorkerSlotReservation',N'WorkerExecutionDisposition',N'WorkerExecutionCommitWitness',N'USP_ClaimWorkCore'))
 THROW 55010,N'EXPORT_QUEUE11_ORIGINAL_EMPTY',2;
CREATE TABLE #SeedApiParameters(ObjectName sysname COLLATE Latin1_General_100_BIN2,Ordinal int,ParameterName sysname COLLATE Latin1_General_100_BIN2,TypeId int,MaxLength int,SysnameAlias bit);
INSERT #SeedApiParameters VALUES
(N'USP_EnqueueWork',1,N'@WorkTypeName',167,128,0),
(N'USP_EnqueueWork',2,N'@PayloadJson',231,-1,0),
(N'USP_EnqueueWork',3,N'@ResultTable',231,256,1),
(N'USP_EnqueueWork',4,N'@KeepData',104,1,0),
(N'USP_EnqueueWork',5,N'@Debug',48,1,0),
(N'USP_EnqueueWork',6,N'@Hilfe',104,1,0),
(N'USP_ClaimWork',1,N'@LeaseDurationSeconds',56,4,0),
(N'USP_ClaimWork',2,N'@ResultTable',231,256,1),
(N'USP_ClaimWork',3,N'@KeepData',104,1,0),
(N'USP_ClaimWork',4,N'@Debug',48,1,0),
(N'USP_ClaimWork',5,N'@Hilfe',104,1,0),
(N'USP_CompleteWork',1,N'@WorkItemId',127,8,0),
(N'USP_CompleteWork',2,N'@ClaimToken',36,16,0),
(N'USP_CompleteWork',3,N'@ResultTable',231,256,1),
(N'USP_CompleteWork',4,N'@KeepData',104,1,0),
(N'USP_CompleteWork',5,N'@Debug',48,1,0),
(N'USP_CompleteWork',6,N'@Hilfe',104,1,0),
(N'USP_FailWork',1,N'@WorkItemId',127,8,0),
(N'USP_FailWork',2,N'@ClaimToken',36,16,0),
(N'USP_FailWork',3,N'@FailureCode',167,64,0),
(N'USP_FailWork',4,N'@FailureMessage',231,-1,0),
(N'USP_FailWork',5,N'@ResultTable',231,256,1),
(N'USP_FailWork',6,N'@KeepData',104,1,0),
(N'USP_FailWork',7,N'@Debug',48,1,0),
(N'USP_FailWork',8,N'@Hilfe',104,1,0);
IF EXISTS(SELECT 1 FROM #SeedApiParameters e LEFT JOIN sys.parameters p ON p.object_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(e.ObjectName),N'P') AND p.parameter_id=e.Ordinal WHERE p.parameter_id IS NULL OR CONVERT(varbinary(max),p.name)<>CONVERT(varbinary(max),e.ParameterName) OR p.system_type_id<>e.TypeId OR p.user_type_id<>CASE WHEN e.SysnameAlias=1 THEN TYPE_ID(N'sysname') ELSE e.TypeId END OR p.max_length<>e.MaxLength OR p.is_output<>0 OR p.is_readonly<>0)
 OR EXISTS(SELECT 1 FROM #SeedApiParameters e GROUP BY e.ObjectName HAVING COUNT(*)<>(SELECT COUNT(*) FROM sys.parameters p WHERE p.object_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(e.ObjectName),N'P')))
 THROW 55010,N'EXPORT_QUEUE11_ORIGINAL_API_BINDING',7;
DROP TABLE #SeedApiParameters;
-- Kanonischer vorhandener JSON-Handler erfüllt den Registrierungsvertrag; er wird niemals aufgerufen.
DECLARE @Handler int=OBJECT_ID(N'toolbelt_core.USP_WriteEventInternal',N'P');
IF @Handler IS NULL OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=@Handler)<>1
 OR NOT EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=@Handler AND parameter_id=1 AND name=N'@PayloadJson' AND system_type_id=231 AND max_length=-1 AND is_output=0)
 THROW 55010,N'Der vorhandene JSON-Payload-Handler besitzt nicht den erwarteten Vertrag.',3;
CREATE TABLE #ExportQueue11Status(Dummy int NULL);
CREATE TABLE #ExportQueue11Claim(Dummy int NULL);
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.export.queue11',@HandlerSchema=N'toolbelt_core',@HandlerProcedure=N'USP_WriteEventInternal',@ParameterMode='JSON_PAYLOAD',@PayloadContractJson=N'{"type":"object"}',@ResultTable=N'#ExportQueue11Status';
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.export.queue11',@PayloadJson=N'{"synthetic":"completed – Ω "}',@ResultTable=N'#ExportQueue11Status';
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.export.queue11',@PayloadJson=N'{"synthetic":"failed – 漢字 "}',@ResultTable=N'#ExportQueue11Status';
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.export.queue11',@PayloadJson=N'{"synthetic":"queued – ä "}',@ResultTable=N'#ExportQueue11Status';
EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=86400,@ResultTable=N'#ExportQueue11Claim';
DECLARE @First bigint=(SELECT WorkItemId FROM #ExportQueue11Claim),@Token uniqueidentifier=(SELECT ClaimToken FROM #ExportQueue11Claim);
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@First,@ClaimToken=@Token,@ResultTable=N'#ExportQueue11Status';
EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=86400,@ResultTable=N'#ExportQueue11Claim';
SELECT @First=WorkItemId,@Token=ClaimToken FROM #ExportQueue11Claim;
EXEC toolbelt_core.USP_FailWork @WorkItemId=@First,@ClaimToken=@Token,@FailureCode='SYNTHETIC.FAIL',@FailureMessage=N'Synthetic ä 中  ',@ResultTable=N'#ExportQueue11Status';
IF (SELECT COUNT(*) FROM toolbelt_core.WorkItem)<>3 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='COMPLETED')<>1
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='FAILED')<>1 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE Status='CLAIMED') OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='QUEUED')<>1
 THROW 55010,N'Die drei Original-API-Zustände fehlen.',4;
IF (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#ExportQueue11Status'))<>22
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#ExportQueue11Claim'))<>8
 THROW 55010,N'EXPORT_QUEUE11_ORIGINAL_RESULT_SHAPES',8;
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

-- Alle eigenen sechs Bindungen und sämtliche Kollisionen vor der ersten Annotation prüfen.
CREATE TABLE #OwnBindings(SchemaName sysname COLLATE Latin1_General_100_BIN2,TableName sysname COLLATE Latin1_General_100_BIN2,ColumnName sysname COLLATE Latin1_General_100_BIN2,ObjectId int NULL,ColumnId int NULL);
INSERT #OwnBindings(SchemaName,TableName,ColumnName) VALUES
(N'toolbelt_core',N'WorkType',N'WorkTypeName'),
(N'toolbelt_core',N'WorkItem',N'PayloadJson'),
(N'toolbelt_core',N'ExecutionCancellation',N'CancellationReason'),
(N'toolbelt_core',N'SecondSessionProvider',N'ModifiedBy'),
(N'toolbelt_core',N'EventLog',N'Message'),
(N'toolbelt_file',N'FileContentRootAllowlist',N'Description');
UPDATE #OwnBindings SET ObjectId=OBJECT_ID(QUOTENAME(SchemaName)+N'.'+QUOTENAME(TableName),N'U');
UPDATE #OwnBindings SET ColumnId=COLUMNPROPERTY(ObjectId,ColumnName,'ColumnId');
IF (SELECT COUNT(*) FROM #OwnBindings)<>6 OR EXISTS(SELECT 1 FROM #OwnBindings b WHERE ObjectId IS NULL OR ColumnId IS NULL
 OR EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=b.ObjectId AND
  (p.name=N'Toolbelt.Test.ExportQueue11' OR (p.name=N'MS_Description' AND p.minor_id IN(0,b.ColumnId) AND NOT(b.SchemaName=N'toolbelt_file' AND b.TableName=N'FileContentRootAllowlist' AND p.minor_id=0)))))
 THROW 55010,N'EXPORT_QUEUE11_ANNOTATION_COLLISION',5;
DECLARE @Schema sysname,@Table sysname,@Column sysname;
DECLARE annotations CURSOR LOCAL FAST_FORWARD FOR SELECT SchemaName,TableName,ColumnName FROM #OwnBindings ORDER BY SchemaName,TableName;
OPEN annotations;FETCH NEXT FROM annotations INTO @Schema,@Table,@Column;
WHILE @@FETCH_STATUS=0 BEGIN
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Test.ExportQueue11',@value=271828,@level0type=N'SCHEMA',@level0name=@Schema,@level1type=N'TABLE',@level1name=@Table;
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Test.ExportQueue11',@value=N'Synthetic legacy column 中 ',@level0type=N'SCHEMA',@level0name=@Schema,@level1type=N'TABLE',@level1name=@Table,@level2type=N'COLUMN',@level2name=@Column;
 IF NOT(@Schema=N'toolbelt_file' AND @Table=N'FileContentRootAllowlist')
  EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Synthetic legacy table ä ',@level0type=N'SCHEMA',@level0name=@Schema,@level1type=N'TABLE',@level1name=@Table;
 EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Synthetic legacy column 中 ',@level0type=N'SCHEMA',@level0name=@Schema,@level1type=N'TABLE',@level1name=@Table,@level2type=N'COLUMN',@level2name=@Column;
 FETCH NEXT FROM annotations INTO @Schema,@Table,@Column;
END;
CLOSE annotations;DEALLOCATE annotations;
DROP TABLE #OwnBindings;DROP TABLE #ExportQueue11Claim;DROP TABLE #ExportQueue11Status;
IF @@TRANCOUNT<>0 THROW 55010,N'EXPORT_QUEUE11_SESSION',6;
IF XACT_STATE()<>0 THROW 55010,N'EXPORT_QUEUE11_SESSION',6;
