-- Ausschließlich eigene frisch exportiert installierte Testdatenbank.
-- Direkte synthetische Tabellenfixtures qualifizieren Persistenz, keine Worker-/RPC-Ausführung.
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF @@TRANCOUNT<>0
 THROW 54980,N'Exportfixture verlangt eine frische neutrale Sitzung.',1;
IF XACT_STATE()<>0
 THROW 54980,N'Exportfixture verlangt eine frische neutrale Sitzung.',1;
IF (@@OPTIONS&2)<>0
 THROW 54980,N'Exportfixture verlangt eine frische neutrale Sitzung.',1;
IF @@LOCK_TIMEOUT<>-1
 THROW 54980,N'Exportfixture verlangt eine frische neutrale Sitzung.',1;
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration)
 OR EXISTS(SELECT 1 FROM toolbelt_core.ExecutionCancellation)
 OR EXISTS(SELECT 1 FROM toolbelt_core.SecondSessionProvider)
 OR EXISTS(SELECT 1 FROM toolbelt_core.EventLog)
 OR EXISTS(SELECT 1 FROM toolbelt_file.FileContentRootAllowlist)
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkType)<>1
 OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write' AND IsEnabled=1)
 THROW 54980,N'Exportfixture verlangt den eigenen frischen Objektstand.',2;

-- Eigene Klasse-3-Zeugen: Schema-IDs einmal bytegenau auflösen, keine fremden Schemas.
DECLARE @ExportSchemaCore int=(SELECT schema_id FROM sys.schemas WHERE CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'toolbelt_core')),
 @ExportSchemaFile int=(SELECT schema_id FROM sys.schemas WHERE CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'toolbelt_file'));
IF @ExportSchemaCore IS NULL OR @ExportSchemaFile IS NULL OR @ExportSchemaCore=@ExportSchemaFile
 THROW 54980,N'Die beiden eigenen Schemas sind nicht eindeutig gebunden.',5;
DECLARE @ExportSchemaExpected TABLE(SchemaId int NOT NULL,PropertyName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,ExpectedValue sql_variant NULL,PRIMARY KEY(SchemaId,PropertyName));
INSERT @ExportSchemaExpected(SchemaId,PropertyName,ExpectedValue) VALUES
 (@ExportSchemaCore,N'MS_Description',CONVERT(sql_variant,CONVERT(nvarchar(128),N'Contoso Schema – Unicode Ω  '))),
 (@ExportSchemaFile,N'MS_Description',CONVERT(sql_variant,CONVERT(nvarchar(128),N'Fabrikam Schema – Padding 中  '))),
 (@ExportSchemaCore,N'Toolbelt.Test.ExportSchema.Typed',CONVERT(sql_variant,CONVERT(varbinary(5),0x00017F80FF))),
 (@ExportSchemaFile,N'Toolbelt.Test.ExportSchema.Typed',CONVERT(sql_variant,CONVERT(int,7))),
 (@ExportSchemaCore,N'Toolbelt.Test.ExportSchema.Null',CONVERT(sql_variant,NULL));
-- Alle fünf Kollisionen gemeinsam vor dem ersten Add abweisen; nichts übernehmen/überschreiben.
-- Nur diese fünf Adds liegen in der eigenen kleinen Transaktionsgrenze.
IF EXISTS(SELECT 1 FROM sys.extended_properties p JOIN @ExportSchemaExpected e
 ON p.class=3 AND p.major_id=e.SchemaId AND p.minor_id=0 AND p.name=e.PropertyName COLLATE DATABASE_DEFAULT)
 THROW 54980,N'Eigene Schemaannotation ist bereits belegt.',6;
DECLARE @ExportSchemaCoreDescription nvarchar(128)=N'Contoso Schema – Unicode Ω  ',
 @ExportSchemaFileDescription nvarchar(128)=N'Fabrikam Schema – Padding 中  ',
 @ExportSchemaBinary varbinary(5)=0x00017F80FF,@ExportSchemaInteger int=7;
BEGIN TRY
 BEGIN TRANSACTION;
 EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=@ExportSchemaCoreDescription,@level0type=N'SCHEMA',@level0name=N'toolbelt_core';
 EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=@ExportSchemaFileDescription,@level0type=N'SCHEMA',@level0name=N'toolbelt_file';
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Test.ExportSchema.Typed',@value=@ExportSchemaBinary,@level0type=N'SCHEMA',@level0name=N'toolbelt_core';
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Test.ExportSchema.Typed',@value=@ExportSchemaInteger,@level0type=N'SCHEMA',@level0name=N'toolbelt_file';
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Test.ExportSchema.Null',@value=NULL,@level0type=N'SCHEMA',@level0name=N'toolbelt_core';
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 54980,N'Schemaannotationssetup hinterließ keine neutrale Sitzung.',7;
IF XACT_STATE()<>0 THROW 54980,N'Schemaannotationssetup hinterließ keine neutrale Sitzung.',7;
IF (@@OPTIONS&2)<>0 THROW 54980,N'Schemaannotationssetup hinterließ keine neutrale Sitzung.',7;
IF @@LOCK_TIMEOUT<>-1 THROW 54980,N'Schemaannotationssetup hinterließ keine neutrale Sitzung.',7;
-- Sechs eigene class1/minor0-Zeugen auf drei bestehenden CREATE OR ALTER-Objekten.
-- Typ/Schema/Name und typisierte Releaseherkunft einmal exakt binden; kein SourceHash-Gate.
DECLARE @ExportObjectBindings TABLE
(
 ObjectName sysname COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
 ObjectType char(2) NOT NULL,ObjectId int NULL,
 ModuleId nvarchar(256) COLLATE Latin1_General_100_BIN2 NOT NULL,
 ModuleVersion nvarchar(64) COLLATE Latin1_General_100_BIN2 NOT NULL
);
INSERT @ExportObjectBindings(ObjectName,ObjectType,ObjectId,ModuleId,ModuleVersion) VALUES
 (N'USP_PrepareResultTable','P',OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P'),N'toolbelt.core.result-table',N'1.0.0'),
 (N'SVF_CurrentExecutionId','FN',OBJECT_ID(N'toolbelt_core.SVF_CurrentExecutionId',N'FN'),N'toolbelt.core.execution-context',N'1.0.0'),
 (N'VW_WorkQueue','V',OBJECT_ID(N'toolbelt_core.VW_WorkQueue',N'V'),N'toolbelt.core.work-queue',N'2.1.0');
IF (SELECT COUNT(DISTINCT ObjectId) FROM @ExportObjectBindings)<>3
 OR EXISTS(SELECT 1 FROM @ExportObjectBindings b
 LEFT JOIN sys.objects o ON o.object_id=b.ObjectId
 LEFT JOIN sys.schemas s ON s.schema_id=o.schema_id
 LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id
 WHERE o.object_id IS NULL OR CONVERT(varbinary(max),o.type)<>CONVERT(varbinary(max),b.ObjectType) OR m.definition IS NULL
 OR CONVERT(varbinary(max),o.name)<>CONVERT(varbinary(max),b.ObjectName)
 OR CONVERT(varbinary(max),s.name)<>CONVERT(varbinary(max),N'toolbelt_core')
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=b.ObjectId AND p.minor_id=0
 AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),N'Toolbelt.ModuleId')
 AND SQL_VARIANT_PROPERTY(p.value,'BaseType')=N'nvarchar'
 AND CONVERT(varbinary(max),p.value)=CONVERT(varbinary(max),b.ModuleId))
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=b.ObjectId AND p.minor_id=0
 AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),N'Toolbelt.ModuleVersion')
 AND SQL_VARIANT_PROPERTY(p.value,'BaseType')=N'nvarchar'
 AND CONVERT(varbinary(max),p.value)=CONVERT(varbinary(max),b.ModuleVersion)))
 THROW 54980,N'Die drei eigenen Objektannotationsziele sind nicht exakt gebunden.',8;
DECLARE @ExportObjectExpected TABLE
(
 ObjectId int NOT NULL,PropertyName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,
 ExpectedValue sql_variant NOT NULL,PRIMARY KEY(ObjectId,PropertyName)
);
INSERT @ExportObjectExpected(ObjectId,PropertyName,ExpectedValue) VALUES
 ((SELECT ObjectId FROM @ExportObjectBindings WHERE ObjectName=N'USP_PrepareResultTable'),N'Toolbelt.Test.ExportObject.Typed',CONVERT(sql_variant,CONVERT(int,7))),
 ((SELECT ObjectId FROM @ExportObjectBindings WHERE ObjectName=N'USP_PrepareResultTable'),N'MS_Description',CONVERT(sql_variant,CONVERT(nvarchar(128),N'Contoso Procedure – Unicode Ω  '))),
 ((SELECT ObjectId FROM @ExportObjectBindings WHERE ObjectName=N'SVF_CurrentExecutionId'),N'Toolbelt.Test.ExportObject.Typed',CONVERT(sql_variant,CONVERT(varbinary(5),0x00017F80FF))),
 ((SELECT ObjectId FROM @ExportObjectBindings WHERE ObjectName=N'SVF_CurrentExecutionId'),N'MS_Description',CONVERT(sql_variant,CONVERT(nvarchar(128),N'Fabrikam Function – Padding 中  '))),
 ((SELECT ObjectId FROM @ExportObjectBindings WHERE ObjectName=N'VW_WorkQueue'),N'Toolbelt.Test.ExportObject.Typed',CONVERT(sql_variant,CONVERT(nvarchar(128),N'Synthetic view – Padding Ω  '))),
 ((SELECT ObjectId FROM @ExportObjectBindings WHERE ObjectName=N'VW_WorkQueue'),N'MS_Description',CONVERT(sql_variant,CONVERT(nvarchar(128),N'Contoso View – Unicode Ω  ')));
-- Alle sechs Kollisionen gemeinsam vor dem ersten eigenen Add abweisen.
IF EXISTS(SELECT 1 FROM sys.extended_properties p JOIN @ExportObjectExpected e
 ON p.class=1 AND p.major_id=e.ObjectId AND p.minor_id=0
 AND p.name COLLATE DATABASE_DEFAULT=e.PropertyName COLLATE DATABASE_DEFAULT)
 THROW 54980,N'Eigene Objektannotation ist bereits belegt.',9;
DECLARE @ExportObjectProcedureTyped int=7,@ExportObjectFunctionTyped varbinary(5)=0x00017F80FF,
 @ExportObjectViewTyped nvarchar(128)=N'Synthetic view – Padding Ω  ',
 @ExportObjectProcedureDescription nvarchar(128)=N'Contoso Procedure – Unicode Ω  ',
 @ExportObjectFunctionDescription nvarchar(128)=N'Fabrikam Function – Padding 中  ',
 @ExportObjectViewDescription nvarchar(128)=N'Contoso View – Unicode Ω  ';
-- Ausschließlich diese sechs eigenen Adds bilden die kleine Transaktionsgrenze.
BEGIN TRY
 BEGIN TRANSACTION;
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Test.ExportObject.Typed',@value=@ExportObjectProcedureTyped,@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=N'PROCEDURE',@level1name=N'USP_PrepareResultTable';
 EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=@ExportObjectProcedureDescription,@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=N'PROCEDURE',@level1name=N'USP_PrepareResultTable';
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Test.ExportObject.Typed',@value=@ExportObjectFunctionTyped,@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=N'FUNCTION',@level1name=N'SVF_CurrentExecutionId';
 EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=@ExportObjectFunctionDescription,@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=N'FUNCTION',@level1name=N'SVF_CurrentExecutionId';
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Test.ExportObject.Typed',@value=@ExportObjectViewTyped,@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=N'VIEW',@level1name=N'VW_WorkQueue';
 EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=@ExportObjectViewDescription,@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=N'VIEW',@level1name=N'VW_WorkQueue';
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
IF @@TRANCOUNT<>0 THROW 54980,N'Objektannotationssetup hinterließ keine neutrale Sitzung.',10;
IF XACT_STATE()<>0 THROW 54980,N'Objektannotationssetup hinterließ keine neutrale Sitzung.',10;
CREATE TABLE #ExportWorkTypeResult(Dummy int NULL);
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.export.sentinel',
 @HandlerSchema=N'toolbelt_core',@HandlerProcedure=N'USP_WriteEventInternal',
 @ParameterMode='JSON_PAYLOAD',@PayloadContractJson=N'{"type":"object","synthetic":true}',
 @DefaultTimeoutSeconds=47,@Description=N'Synthetic sentinel ä ',@ResultTable=N'#ExportWorkTypeResult';
DECLARE @Rv binary(8)=(SELECT CONVERT(binary(8),RowVersion) FROM toolbelt_core.WorkType WHERE WorkTypeName='test.export.sentinel');
EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName='test.export.sentinel',@ExpectedRowVersion=@Rv,
 @DisabledReason=N'Synthetic disabled 中 ',@ResultTable=N'#ExportWorkTypeResult';
-- Absichtliche Event-Reaktivierung ist der einzige fachlich erwartete Zeilendelta.
SET @Rv=(SELECT CONVERT(binary(8),RowVersion) FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write');
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='toolbelt.event-log.write',
 @HandlerSchema=N'toolbelt_core',@HandlerProcedure=N'USP_WriteEventInternal',
 @ParameterMode='JSON_PAYLOAD',@PayloadContractJson=N'{"type":"object","synthetic":true}',
 @DefaultTimeoutSeconds=31,@IsIdempotent=1,@Description=N'Synthetic pre-repeat drift',
 @AllowUpdate=1,@ExpectedRowVersion=@Rv,@ResultTable=N'#ExportWorkTypeResult';
SET @Rv=(SELECT CONVERT(binary(8),RowVersion) FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write');
EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName='toolbelt.event-log.write',@ExpectedRowVersion=@Rv,
 @DisabledReason=N'Synthetic pre-repeat disable',@ResultTable=N'#ExportWorkTypeResult';

DECLARE @Type bigint=(SELECT WorkTypeId FROM toolbelt_core.WorkType WHERE WorkTypeName='test.export.sentinel'),
 @Now datetime2(7)='2026-01-02T03:04:05.1234567';
-- Ruhender Verbund: keine CLAIMED-Zeile; Barrierhistorie darf auf einen abgeschlossenen Claim verweisen.
INSERT toolbelt_core.WorkItem(WorkTypeId,PayloadJson,Status,EnqueuedAtUtc,EnqueuedBy,ExecutionMode,
 ClaimGeneration,ClaimToken,ClaimedAtUtc,ClaimedBy,LeaseDurationSeconds,LeaseUntilUtc,LastHeartbeatAtUtc,
 CycleAttemptCount,CompletedAtUtc,CompletedBy,FailedAtUtc,FailedBy,FailureCode,FailureMessage,
 NextAttemptAtUtc,LastErrorCode,LastErrorMessage,LastRetryScheduledAtUtc,LastRetryScheduledBy,
 DeadLetteredAtUtc,DeadLetteredBy,BarrierEpoch)
SELECT @Type,N'{"synthetic":"ä 中  ","ordinal":'+CONVERT(nvarchar(3),v.Ordinal)+N'}',v.Status,@Now,N'Synthetic caller ',
 CASE WHEN v.Status='BARRIER_WAIT' THEN 'DRAIN_BARRIER' ELSE 'SHARED' END,
 CASE WHEN v.Status IN('QUEUED','BARRIER_WAIT') THEN 0 ELSE 1 END,
 CASE WHEN v.Status IN('QUEUED','BARRIER_WAIT','RETRY_WAIT') THEN NULL ELSE NEWID() END,
 CASE WHEN v.Status IN('QUEUED','BARRIER_WAIT','RETRY_WAIT') THEN NULL ELSE @Now END,
 CASE WHEN v.Status IN('QUEUED','BARRIER_WAIT','RETRY_WAIT') THEN NULL ELSE N'Synthetic caller ' END,
 CASE WHEN v.Status IN('QUEUED','BARRIER_WAIT','RETRY_WAIT') THEN NULL ELSE 300 END,
 CASE WHEN v.Status IN('QUEUED','BARRIER_WAIT','RETRY_WAIT') THEN NULL ELSE DATEADD(SECOND,300,@Now) END,
 CASE WHEN v.Status IN('QUEUED','BARRIER_WAIT','RETRY_WAIT') THEN NULL ELSE @Now END,
 CASE WHEN v.Status IN('QUEUED','BARRIER_WAIT') THEN 0 WHEN v.Status='DEAD_LETTER' THEN 3 ELSE 1 END,
 CASE WHEN v.Status='COMPLETED' THEN @Now END,CASE WHEN v.Status='COMPLETED' THEN N'Synthetic caller ' END,
 CASE WHEN v.Status='FAILED' THEN @Now END,CASE WHEN v.Status='FAILED' THEN N'Synthetic caller ' END,
 CASE WHEN v.Status IN('FAILED','DEAD_LETTER') THEN 'TEST.EXPORT' END,
 CASE WHEN v.Status IN('FAILED','DEAD_LETTER') THEN N'Synthetic failure 中 ' END,
 CASE WHEN v.Status='RETRY_WAIT' THEN DATEADD(SECOND,60,@Now) END,
 CASE WHEN v.Status IN('RETRY_WAIT','DEAD_LETTER') THEN 'TEST.EXPORT' END,
 CASE WHEN v.Status IN('RETRY_WAIT','DEAD_LETTER') THEN N'Synthetic retry ä ' END,
 CASE WHEN v.Status='RETRY_WAIT' THEN @Now END,CASE WHEN v.Status='RETRY_WAIT' THEN N'Synthetic caller ' END,
 CASE WHEN v.Status='DEAD_LETTER' THEN @Now END,CASE WHEN v.Status='DEAD_LETTER' THEN N'Synthetic caller ' END,
 CASE WHEN v.Status='BARRIER_WAIT' THEN 1 ELSE 0 END
FROM(VALUES(1,'COMPLETED'),(2,'COMPLETED'),(3,'COMPLETED'),(4,'QUEUED'),(5,'BARRIER_WAIT'),(6,'RETRY_WAIT'),(7,'FAILED'),(8,'DEAD_LETTER'))v(Ordinal,Status);
INSERT toolbelt_core.WorkQueueBarrierBlocker(BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration,CapturedAtUtc)
SELECT b.WorkItemId,b.BarrierEpoch,c.WorkItemId,c.ClaimGeneration,@Now
 FROM toolbelt_core.WorkItem b CROSS JOIN toolbelt_core.WorkItem c
 WHERE b.PayloadJson LIKE N'%"ordinal":5}' AND c.PayloadJson LIKE N'%"ordinal":1}';
DECLARE @Worker uniqueidentifier='00000000-0000-0000-0000-000000008001';
INSERT toolbelt_core.WorkerRegistration(WorkerId,WorkerGeneration,WorkerToken,OwnerPrincipalId,ProviderKind,State,AdmissionPaused,Capacity,RunMode,LastHeartbeatAtUtc,HeartbeatSeconds,UnreachableSeconds)
VALUES(@Worker,1,'00000000-0000-0000-0000-000000008011',DATABASE_PRINCIPAL_ID(),'EXTERNAL','CLOSED',1,2,'BOUNDED',@Now,15,60),
 (@Worker,2,'00000000-0000-0000-0000-000000008012',DATABASE_PRINCIPAL_ID(),'EXTERNAL','PAUSED',1,3,'CONTINUOUS',@Now,15,60);
;WITH items AS(SELECT TOP(3) WorkItemId,ClaimGeneration,ClaimToken,ROW_NUMBER() OVER(ORDER BY WorkItemId) Ordinal FROM toolbelt_core.WorkItem WHERE Status='COMPLETED' ORDER BY WorkItemId)
INSERT toolbelt_core.WorkerSlotReservation(SlotReservationId,WorkerId,WorkerGeneration,WorkItemId,ClaimGeneration,ClaimToken,ExecutionId,State,IsOccupied,AttemptNonce,BoundPrincipalId,CreatedAtUtc,EndedAtUtc)
SELECT CONVERT(uniqueidentifier,CASE Ordinal WHEN 1 THEN '00000000-0000-0000-0000-000000008021' WHEN 2 THEN '00000000-0000-0000-0000-000000008022' ELSE '00000000-0000-0000-0000-000000008023' END),
 @Worker,1,WorkItemId,ClaimGeneration,ClaimToken,
 CONVERT(uniqueidentifier,CASE Ordinal WHEN 1 THEN '00000000-0000-0000-0000-000000008031' WHEN 2 THEN '00000000-0000-0000-0000-000000008032' ELSE '00000000-0000-0000-0000-000000008033' END),
 CASE Ordinal WHEN 1 THEN 'COMMITTED' WHEN 2 THEN 'ROLLED_BACK' ELSE 'CLOSED' END,0,
 '00000000-0000-0000-0000-000000008041',DATABASE_PRINCIPAL_ID(),@Now,@Now FROM items;
INSERT toolbelt_core.WorkerExecutionDisposition(WorkItemId,SlotReservationId,IsHeld,StopStatus)
 SELECT WorkItemId,SlotReservationId,0,CASE State WHEN 'COMMITTED' THEN 'ALREADY_COMMITTED' ELSE 'NONE' END FROM toolbelt_core.WorkerSlotReservation;
INSERT toolbelt_core.WorkerExecutionCommitWitness(SlotReservationId,AttemptNonce,ExecutionId,ClaimGeneration,RecordedAtUtc)
 SELECT SlotReservationId,AttemptNonce,ExecutionId,ClaimGeneration,@Now FROM toolbelt_core.WorkerSlotReservation WHERE State='COMMITTED';
-- Singleton-RV vor Baseline verändern, ohne Managed-Betrieb zu aktivieren.
UPDATE toolbelt_core.WorkerControlConfiguration SET MaxConcurrentExecutions=2 WHERE ConfigurationId=1;
UPDATE toolbelt_core.WorkQueueManagedGate SET ManagedEnabled=0 WHERE GateId=1;

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

-- Eigene typisierte Annotationen über alle 14 Tabellen, vorhandene fremde Properties niemals übernehmen.
DECLARE @Schema sysname,@Table sysname,@Column sysname,@Id int;
DECLARE annotations CURSOR LOCAL FAST_FORWARD FOR
 SELECT s.name,t.name,MIN(c.name) FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id
 JOIN sys.columns c ON c.object_id=t.object_id AND c.is_identity=0 AND c.system_type_id<>189
 LEFT JOIN sys.extended_properties p ON p.class=1 AND p.major_id=t.object_id AND p.minor_id=0 AND p.name=N'Toolbelt.ModuleId'
 WHERE CONVERT(nvarchar(256),p.value) IN(N'toolbelt.core.work-type',N'toolbelt.core.work-queue',N'toolbelt.core.worker-control',N'toolbelt.core.execution-cancel',N'toolbelt.core.second-session',N'toolbelt.core.event-log')
 OR (s.name=N'toolbelt_file' AND t.name=N'FileContentRootAllowlist')
 GROUP BY s.name,t.name;
OPEN annotations;FETCH NEXT FROM annotations INTO @Schema,@Table,@Column;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @Id=OBJECT_ID(QUOTENAME(@Schema)+N'.'+QUOTENAME(@Table));
 IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@Id AND
 (name=N'Toolbelt.Test.ExportPopulated' OR (name=N'MS_Description' AND minor_id IN(0,COLUMNPROPERTY(@Id,@Column,'ColumnId')) AND NOT(@Schema=N'toolbelt_file' AND @Table=N'FileContentRootAllowlist' AND minor_id=0))))
 THROW 54980,N'Eigene Exportannotation ist bereits belegt.',3;
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Test.ExportPopulated',@value=314159,@level0type=N'SCHEMA',@level0name=@Schema,@level1type=N'TABLE',@level1name=@Table;
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Test.ExportPopulated',@value=N'Synthetic column 中 ',@level0type=N'SCHEMA',@level0name=@Schema,@level1type=N'TABLE',@level1name=@Table,@level2type=N'COLUMN',@level2name=@Column;
 IF @Schema=N'toolbelt_file' AND @Table=N'FileContentRootAllowlist'
 EXEC sys.sp_updateextendedproperty @name=N'MS_Description',@value=N'Synthetic stale description',@level0type=N'SCHEMA',@level0name=@Schema,@level1type=N'TABLE',@level1name=@Table;
 ELSE EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Synthetic table ä ',@level0type=N'SCHEMA',@level0name=@Schema,@level1type=N'TABLE',@level1name=@Table;
 EXEC sys.sp_addextendedproperty @name=N'MS_Description',@value=N'Synthetic column 中 ',@level0type=N'SCHEMA',@level0name=@Schema,@level1type=N'TABLE',@level1name=@Table,@level2type=N'COLUMN',@level2name=@Column;
 FETCH NEXT FROM annotations INTO @Schema,@Table,@Column;
END;
CLOSE annotations;DEALLOCATE annotations;
DROP TABLE #ExportWorkTypeResult;
IF @@TRANCOUNT<>0 THROW 54980,N'Exportsetup hinterließ eine Transaktion.',4;
IF XACT_STATE()<>0 THROW 54980,N'Exportsetup hinterließ eine Transaktion.',4;
