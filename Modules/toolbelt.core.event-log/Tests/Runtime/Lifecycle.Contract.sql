SET NOCOUNT ON;
IF OBJECT_ID(N'toolbelt_core.EventLog',N'U') IS NULL
 OR OBJECT_ID(N'toolbelt_core.VW_Events',N'V') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_WriteEvent',N'P') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_WriteEventInternal',N'P') IS NULL
 OR OBJECT_ID(N'toolbelt_core.USP_DeleteEventsBefore',N'P') IS NULL
    THROW 52730,N'Event-Log-Objektbestand ist unvollständig.',1;
IF NOT EXISTS(SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N'toolbelt_core.EventLog') AND name=N'PK_EventLog')
 OR NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'toolbelt_core.EventLog') AND name=N'IX_EventLog_OccurredAtUtc_EventId')
    THROW 52731,N'Benannte Event-Log-Artefakte fehlen.',1;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write' AND HandlerSchema=N'toolbelt_core' AND HandlerProcedure=N'USP_WriteEventInternal' AND ParameterMode='JSON_PAYLOAD' AND IsEnabled=1)
    THROW 52732,N'Interner Event-Log-Work-Type fehlt oder ist inkonsistent.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.event-log.Version' AND CONVERT(nvarchar(32),value)=N'1.0.0')
    THROW 52733,N'Event-Log-Modulmarker fehlt.',1;
PRINT N'Event Log Lifecycle: erfolgreich';
