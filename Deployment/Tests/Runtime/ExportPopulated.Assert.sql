-- Parameter kommen ausschließlich aus privatem Adaptermemory; keine permanente Snapshot-Tabelle.
SET NOCOUNT ON;
IF @Phase NOT IN(1,2) OR @@TRANCOUNT<>0 OR XACT_STATE()<>0 OR (@@OPTIONS&2)<>0 OR @@LOCK_TIMEOUT<>-1
 THROW 54982,N'Der Exportrepeat hinterließ keinen neutralen Zustand.',1;
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
