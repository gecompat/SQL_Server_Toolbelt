-- Parameter kommen ausschließlich aus privatem Adaptermemory; keine permanente Snapshot-Tabelle.
SET NOCOUNT ON;
IF @Phase NOT IN(1,2)
 THROW 54982,N'Der Exportrepeat hinterließ keinen neutralen Zustand.',1;
IF @@TRANCOUNT<>0
 THROW 54982,N'Der Exportrepeat hinterließ keinen neutralen Zustand.',1;
IF XACT_STATE()<>0
 THROW 54982,N'Der Exportrepeat hinterließ keinen neutralen Zustand.',1;
IF (@@OPTIONS&2)<>0
 THROW 54982,N'Der Exportrepeat hinterließ keinen neutralen Zustand.',1;
IF @@LOCK_TIMEOUT<>-1
 THROW 54982,N'Der Exportrepeat hinterließ keinen neutralen Zustand.',1;
-- Eigene Klasse-3-Zeugen: Schema-IDs einmal bytegenau auflösen, keine fremden Schemas.
DECLARE @ExportSchemaCore int=(SELECT schema_id FROM sys.schemas WHERE CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'toolbelt_core')),
 @ExportSchemaFile int=(SELECT schema_id FROM sys.schemas WHERE CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'toolbelt_file'));
IF @ExportSchemaCore IS NULL OR @ExportSchemaFile IS NULL OR @ExportSchemaCore=@ExportSchemaFile
 THROW 54982,N'Die beiden eigenen Schemas sind nicht eindeutig gebunden.',8;
DECLARE @ExportSchemaExpected TABLE(SchemaId int NOT NULL,PropertyName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,ExpectedValue sql_variant NULL,PRIMARY KEY(SchemaId,PropertyName));
INSERT @ExportSchemaExpected(SchemaId,PropertyName,ExpectedValue) VALUES
 (@ExportSchemaCore,N'MS_Description',CONVERT(sql_variant,CONVERT(nvarchar(128),N'Contoso Schema – Unicode Ω  '))),
 (@ExportSchemaFile,N'MS_Description',CONVERT(sql_variant,CONVERT(nvarchar(128),N'Fabrikam Schema – Padding 中  '))),
 (@ExportSchemaCore,N'Toolbelt.Test.ExportSchema.Typed',CONVERT(sql_variant,CONVERT(varbinary(5),0x00017F80FF))),
 (@ExportSchemaFile,N'Toolbelt.Test.ExportSchema.Typed',CONVERT(sql_variant,CONVERT(int,7))),
 (@ExportSchemaCore,N'Toolbelt.Test.ExportSchema.Null',CONVERT(sql_variant,NULL));
-- Vollständiger typisierter Erwartungstupel, nicht nur Anzahl oder Textkonvertierung.
-- Ein vorhandener NULL-Zeuge besitzt HasValue=0; eine fehlende Property besitzt keine Zeile.
IF (SELECT COUNT(*) FROM sys.extended_properties p JOIN @ExportSchemaExpected e ON p.class=3 AND p.major_id=e.SchemaId AND p.minor_id=0 AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),e.PropertyName))<>5
 OR EXISTS(SELECT CONVERT(tinyint,3),e.SchemaId,CONVERT(int,0),CONVERT(varbinary(max),e.PropertyName) PropertyName,
 CONVERT(varbinary(max),CONVERT(bit,CASE WHEN e.ExpectedValue IS NULL THEN 0 ELSE 1 END)) HasValue,
 CONVERT(varbinary(max),CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(e.ExpectedValue,'BaseType'))) BaseType,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(e.ExpectedValue,'MaxLength'))) MaxLength,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(e.ExpectedValue,'Precision'))) PrecisionValue,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(e.ExpectedValue,'Scale'))) ScaleValue,
 CONVERT(varbinary(max),CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(e.ExpectedValue,'Collation'))) CollationValue,
 CONVERT(varbinary(max),e.ExpectedValue) ValueBytes FROM @ExportSchemaExpected e EXCEPT SELECT p.class,p.major_id,p.minor_id,CONVERT(varbinary(max),p.name) PropertyName,
 CONVERT(varbinary(max),CONVERT(bit,CASE WHEN p.value IS NULL THEN 0 ELSE 1 END)) HasValue,
 CONVERT(varbinary(max),CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,'BaseType'))) BaseType,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(p.value,'MaxLength'))) MaxLength,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(p.value,'Precision'))) PrecisionValue,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(p.value,'Scale'))) ScaleValue,
 CONVERT(varbinary(max),CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,'Collation'))) CollationValue,
 CONVERT(varbinary(max),p.value) ValueBytes FROM sys.extended_properties p JOIN @ExportSchemaExpected e ON p.class=3 AND p.major_id=e.SchemaId AND p.minor_id=0 AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),e.PropertyName))
 OR EXISTS(SELECT p.class,p.major_id,p.minor_id,CONVERT(varbinary(max),p.name) PropertyName,
 CONVERT(varbinary(max),CONVERT(bit,CASE WHEN p.value IS NULL THEN 0 ELSE 1 END)) HasValue,
 CONVERT(varbinary(max),CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,'BaseType'))) BaseType,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(p.value,'MaxLength'))) MaxLength,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(p.value,'Precision'))) PrecisionValue,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(p.value,'Scale'))) ScaleValue,
 CONVERT(varbinary(max),CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,'Collation'))) CollationValue,
 CONVERT(varbinary(max),p.value) ValueBytes FROM sys.extended_properties p JOIN @ExportSchemaExpected e ON p.class=3 AND p.major_id=e.SchemaId AND p.minor_id=0 AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),e.PropertyName) EXCEPT SELECT CONVERT(tinyint,3),e.SchemaId,CONVERT(int,0),CONVERT(varbinary(max),e.PropertyName) PropertyName,
 CONVERT(varbinary(max),CONVERT(bit,CASE WHEN e.ExpectedValue IS NULL THEN 0 ELSE 1 END)) HasValue,
 CONVERT(varbinary(max),CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(e.ExpectedValue,'BaseType'))) BaseType,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(e.ExpectedValue,'MaxLength'))) MaxLength,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(e.ExpectedValue,'Precision'))) PrecisionValue,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(e.ExpectedValue,'Scale'))) ScaleValue,
 CONVERT(varbinary(max),CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(e.ExpectedValue,'Collation'))) CollationValue,
 CONVERT(varbinary(max),e.ExpectedValue) ValueBytes FROM @ExportSchemaExpected e)
 THROW 54982,N'Die fünf eigenen typisierten Schemaannotationzeugen wurden verändert.',9;
IF (SELECT COUNT(*) FROM sys.extended_properties p WHERE p.class=3 AND p.major_id IN(@ExportSchemaCore,@ExportSchemaFile) AND p.minor_id=0)<5
 OR (SELECT COUNT(*) FROM sys.extended_properties p WHERE p.class=3 AND p.major_id=@ExportSchemaCore AND p.minor_id=0)<3
 OR (SELECT COUNT(*) FROM sys.extended_properties p WHERE p.class=3 AND p.major_id=@ExportSchemaFile AND p.minor_id=0)<2
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=3 AND p.major_id=@ExportSchemaCore AND p.minor_id=0
 AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),N'Toolbelt.Test.ExportSchema.Null') AND p.value IS NULL)
 THROW 54982,N'Der vollständige Schemaannotations- und NULL-Zeuge fehlt.',10;
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
 THROW 54982,N'Die drei eigenen Objektannotationsziele sind nicht exakt gebunden.',11;
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
-- Vollständiger Schlüssel und typisierter Werttupel in beiden Richtungen, nicht nur COUNT.
IF (SELECT COUNT(*) FROM sys.extended_properties p JOIN @ExportObjectExpected e
 ON p.class=1 AND p.major_id=e.ObjectId AND p.minor_id=0
 AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),e.PropertyName))<>6
 OR EXISTS(SELECT CONVERT(tinyint,1) ClassValue,e.ObjectId,CONVERT(int,0) MinorId,
 CONVERT(varbinary(max),e.PropertyName) PropertyName,
 CONVERT(varbinary(max),CONVERT(bit,CASE WHEN e.ExpectedValue IS NULL THEN 0 ELSE 1 END)) HasValue,
 CONVERT(varbinary(max),CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(e.ExpectedValue,'BaseType'))) BaseType,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(e.ExpectedValue,'MaxLength'))) MaxLength,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(e.ExpectedValue,'Precision'))) PrecisionValue,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(e.ExpectedValue,'Scale'))) ScaleValue,
 CONVERT(varbinary(max),CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(e.ExpectedValue,'Collation'))) CollationValue,
 CONVERT(varbinary(max),e.ExpectedValue) ValueBytes FROM @ExportObjectExpected e
 EXCEPT SELECT p.class,p.major_id,p.minor_id,CONVERT(varbinary(max),p.name) PropertyName,
 CONVERT(varbinary(max),CONVERT(bit,CASE WHEN p.value IS NULL THEN 0 ELSE 1 END)) HasValue,
 CONVERT(varbinary(max),CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,'BaseType'))) BaseType,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(p.value,'MaxLength'))) MaxLength,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(p.value,'Precision'))) PrecisionValue,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(p.value,'Scale'))) ScaleValue,
 CONVERT(varbinary(max),CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,'Collation'))) CollationValue,
 CONVERT(varbinary(max),p.value) ValueBytes FROM sys.extended_properties p JOIN @ExportObjectExpected e
 ON p.class=1 AND p.major_id=e.ObjectId AND p.minor_id=0
 AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),e.PropertyName))
 OR EXISTS(SELECT p.class,p.major_id,p.minor_id,CONVERT(varbinary(max),p.name) PropertyName,
 CONVERT(varbinary(max),CONVERT(bit,CASE WHEN p.value IS NULL THEN 0 ELSE 1 END)) HasValue,
 CONVERT(varbinary(max),CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,'BaseType'))) BaseType,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(p.value,'MaxLength'))) MaxLength,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(p.value,'Precision'))) PrecisionValue,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(p.value,'Scale'))) ScaleValue,
 CONVERT(varbinary(max),CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,'Collation'))) CollationValue,
 CONVERT(varbinary(max),p.value) ValueBytes FROM sys.extended_properties p JOIN @ExportObjectExpected e
 ON p.class=1 AND p.major_id=e.ObjectId AND p.minor_id=0
 AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),e.PropertyName)
 EXCEPT SELECT CONVERT(tinyint,1) ClassValue,e.ObjectId,CONVERT(int,0) MinorId,
 CONVERT(varbinary(max),e.PropertyName) PropertyName,
 CONVERT(varbinary(max),CONVERT(bit,CASE WHEN e.ExpectedValue IS NULL THEN 0 ELSE 1 END)) HasValue,
 CONVERT(varbinary(max),CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(e.ExpectedValue,'BaseType'))) BaseType,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(e.ExpectedValue,'MaxLength'))) MaxLength,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(e.ExpectedValue,'Precision'))) PrecisionValue,
 CONVERT(varbinary(max),CONVERT(int,SQL_VARIANT_PROPERTY(e.ExpectedValue,'Scale'))) ScaleValue,
 CONVERT(varbinary(max),CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(e.ExpectedValue,'Collation'))) CollationValue,
 CONVERT(varbinary(max),e.ExpectedValue) ValueBytes FROM @ExportObjectExpected e)
 THROW 54982,N'Die sechs eigenen typisierten Objektannotationzeugen wurden verändert.',12;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueManagedGate WHERE GateId=1 AND ManagedEnabled=0 AND PendingReservationId IS NULL)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE Status='CLAIMED' OR ManagedHold=1)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1 OR State NOT IN('COMMITTED','ROLLED_BACK','CLOSED'))
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition WHERE IsHeld=1)
 THROW 54982,N'Der synthetische Verbund ist nicht ruhend.',2;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.SecondSessionProvider WHERE ProviderName='loopback' AND IsEnabled=0 AND CONVERT(varbinary(max),LinkedServerName)=CONVERT(varbinary(max),N'localhost'))
 THROW 54982,N'Der deaktivierte synthetische Provider wurde verändert.',3;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_file.FileContentRootAllowlist') AND minor_id=0 AND name=N'MS_Description'
 AND SQL_VARIANT_PROPERTY(value,'BaseType')='nvarchar'
 AND CONVERT(int,SQL_VARIANT_PROPERTY(value,'MaxLength'))=DATALENGTH(N'Allowlist der Root-Pfade für toolbelt.file.content. Pfade müssen absolut sein; UNC-Pfade sind erlaubt.')
 AND CONVERT(varbinary(max),CONVERT(nvarchar(4000),value))=CONVERT(varbinary(max),N'Allowlist der Root-Pfade für toolbelt.file.content. Pfade müssen absolut sein; UNC-Pfade sind erlaubt.'))
 THROW 54982,N'Die File-Content-Beschreibung ist nicht kanonisch.',4;
IF (SELECT COUNT(*) FROM sys.extended_properties p JOIN sys.tables t ON t.object_id=p.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
 WHERE p.class=1 AND p.name=N'Toolbelt.Test.ExportPopulated' AND p.minor_id=0 AND s.name IN(N'toolbelt_core',N'toolbelt_file'))<>14
 OR (SELECT COUNT(*) FROM sys.extended_properties p JOIN sys.tables t ON t.object_id=p.major_id JOIN sys.schemas s ON s.schema_id=t.schema_id
 WHERE p.class=1 AND p.name=N'Toolbelt.Test.ExportPopulated' AND p.minor_id>0 AND s.name IN(N'toolbelt_core',N'toolbelt_file'))<>14
 THROW 54982,N'Die 14 Tabellen-/Spaltenannotationzeugen sind unvollständig.',7;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write'
 AND CONVERT(varbinary(max),HandlerSchema)=CONVERT(varbinary(max),N'toolbelt_core')
 AND CONVERT(varbinary(max),HandlerProcedure)=CONVERT(varbinary(max),N'USP_WriteEventInternal')
 AND ParameterMode='JSON_PAYLOAD' AND CONVERT(varbinary(max),PayloadContractJson)=CONVERT(varbinary(max),N'{"type":"object"}')
 AND DefaultTimeoutSeconds=30 AND IsIdempotent=0 AND IsEnabled=1
 AND CONVERT(varbinary(max),Description)=CONVERT(varbinary(max),N'Interner Handler für rollback-unabhängige Toolbelt-Events.')
 AND DisabledAtUtc IS NULL AND DisabledBy IS NULL AND DisabledReason IS NULL
 AND (@Phase=2 OR (CONVERT(binary(8),RowVersion)<>@OriginalEventRowVersion
 AND ModifiedAtUtc>=@DeployStartedAtUtc AND ModifiedAtUtc<=SYSUTCDATETIME()
 AND CONVERT(varbinary(max),ModifiedBy)=CONVERT(varbinary(max),ORIGINAL_LOGIN()))))
 THROW 54982,N'Die Eventregistrierung wurde nicht vertragsgemäß kanonisiert.',5;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='test.export.sentinel' AND IsEnabled=0)
 THROW 54982,N'Der eigene fremde Work-Type-Sentinel wurde verändert.',6;
