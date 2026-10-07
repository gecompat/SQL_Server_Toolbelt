:On Error exit
-- Eigene Testdatenbank, installierter Event Log 1.0.0, exklusive neutrale Session.
-- Aus Deployment/ aufrufen; beide Repeats verwenden die echten Deploy-Includes.
-- Synthetische Tabellenzeilen prüfen Persistenz, nicht den Second-Session-Provider.
SET NOCOUNT ON;
IF @@TRANCOUNT <> 0
    THROW 52750, N'Der Event-Repeat benötigt eine Session ohne Callertransaktion.', 1;
IF XACT_STATE() <> 0
    THROW 52750, N'Der Event-Repeat benötigt einen neutralen Transaktionszustand.', 2;
IF (2 & @@OPTIONS) = 2
    THROW 52750, N'Der Event-Repeat benötigt IMPLICIT_TRANSACTIONS OFF.', 3;
IF OBJECT_ID(N'toolbelt_core.EventLog', N'U') IS NULL
 OR OBJECT_ID(N'toolbelt_core.WorkType', N'U') IS NULL
 OR NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0
                AND name = N'Toolbelt.Module.toolbelt.core.event-log.Version'
                AND CONVERT(nvarchar(32), value) = N'1.0.0')
    THROW 52750, N'Der Event-Repeat benötigt das installierte Modul 1.0.0.', 4;
IF NOT EXISTS (SELECT 1 FROM toolbelt_core.WorkType
               WHERE WorkTypeName = 'toolbelt.event-log.write' AND IsEnabled = 1
                 AND HandlerSchema = N'toolbelt_core' AND HandlerProcedure = N'USP_WriteEventInternal')
    THROW 52750, N'Die installierte Event-Registrierung fehlt.', 5;
IF EXISTS (SELECT 1 FROM toolbelt_core.EventLog WHERE EventName IN
           ('test.repeat.null', 'test.repeat.empty', 'test.repeat.unicode',
            'test.repeat.error', 'test.repeat.deleted', 'test.repeat.next'))
 OR EXISTS (SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName = 'test.event-repeat.sentinel')
    THROW 52750, N'Der synthetische Event-Repeat-Scope ist bereits belegt.', 6;
IF EXISTS (SELECT 1 FROM sys.extended_properties
           WHERE class = 1 AND major_id = OBJECT_ID(N'toolbelt_core.EventLog', N'U')
             AND minor_id IN (0, COLUMNPROPERTY(OBJECT_ID(N'toolbelt_core.EventLog', N'U'), N'Message', 'ColumnId'))
             AND name IN (N'Toolbelt.Test.EventRepeat', N'MS_Description'))
    THROW 52750, N'Die eigenen Event-Repeat-Annotationen sind bereits belegt.', 7;
SET XACT_ABORT ON;

CREATE TABLE #tbx_EventRepeat_State
    (Phase int NOT NULL, LastEventIdentity decimal(38,0) NULL,
     SentinelId bigint NULL, DeployStartedAtUtc datetime2(7) NULL,
     DeployPrincipal sysname COLLATE DATABASE_DEFAULT NOT NULL);
INSERT #tbx_EventRepeat_State (Phase, DeployPrincipal) VALUES (0, ORIGINAL_LOGIN());
CREATE TABLE #tbx_EventRepeat_OwnEvents
    (EventId bigint NOT NULL PRIMARY KEY, Role varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL);
CREATE TABLE #tbx_EventRepeat_Snapshot
    (Phase int NOT NULL, Category varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,
     Payload varbinary(max) NOT NULL, PRIMARY KEY (Phase, Category));
SELECT TOP (0) CAST(0 AS int) AS Phase, CONVERT(bigint, WorkTypeId) AS WorkTypeId, WorkTypeName, HandlerSchema,
       HandlerProcedure, ParameterMode, PayloadContractJson, DefaultTimeoutSeconds,
       IsIdempotent, IsEnabled, Description, CreatedAtUtc, CreatedBy, ModifiedAtUtc,
       ModifiedBy, DisabledAtUtc, DisabledBy, DisabledReason, CONVERT(binary(8), RowVersion) AS RowVersion
INTO #tbx_EventRepeat_WorkType FROM toolbelt_core.WorkType;
-- Öffentliche API-Ergebnisse bleiben privat; der Sink verwendet keinen reservierten #tbx_-Namen.
CREATE TABLE #EventRepeatWorkTypeResult (Dummy int NULL);

INSERT toolbelt_core.EventLog
    (OccurredAtUtc, RecordedAtUtc, EventName, EventLevel, Category, Message, DataJson,
     ExecutionId, CorrelationId, Actor, Tenant, SourceDatabaseName, SourceSchemaName,
     SourceObjectName, CallerSessionId, CallerXactState, CallerTransactionCount,
     RemoteSessionId, ErrorNumber, ErrorSeverity, ErrorState, ErrorProcedure, ErrorLine)
OUTPUT inserted.EventId, 'seed' INTO #tbx_EventRepeat_OwnEvents
VALUES
 ('2026-01-02T03:04:05.0000001', '2026-01-02T03:04:05.0000002', 'test.repeat.null', 'INFO', NULL, NULL, NULL,
  '77777777-1111-1111-1111-111111111111', '77777777-2222-2222-2222-222222222222', NULL, NULL, N'Contoso', NULL, NULL, 1, 0, 0, 2, NULL, NULL, NULL, NULL, NULL),
 ('2026-02-03T04:05:06.1234567', '2026-02-03T04:05:06.7654321', 'test.repeat.empty', 'DEBUG', '', N'', N'{}',
  '77777777-3333-3333-3333-333333333333', '77777777-4444-4444-4444-444444444444', N'', N'', N'Fabrikam', N'', N'', 3, 1, 1, 4, 0, 0, 0, N'', 1),
 ('2026-03-04T05:06:07.9999999', '2026-03-04T05:06:08.0000000', 'test.repeat.unicode', 'WARNING', 'synthetic ', N'Unicode ä 中 ', N'{"text":"ä 中 "}',
  '77777777-5555-5555-5555-555555555555', '77777777-6666-6666-6666-666666666666', N'Actor ä ', N'Tenant 中 ', N'Contoso ', N'dbo ', N'Object 中 ', 5, -1, 2, 6, NULL, NULL, NULL, NULL, NULL),
 ('2026-04-05T06:07:08.0000009', '2026-04-05T06:07:08.0000010', 'test.repeat.error', 'CRITICAL', 'errors', N'Synthetic error', N'{"error":true}',
  '77777777-7777-7777-7777-777777777777', '77777777-8888-8888-8888-888888888888', N'Synthetic actor', N'Synthetic tenant', N'AdventureWorks', N'dbo', N'Object', 7, 1, 3, 8, 50000, 25, 255, N'USP_Synthetic ', 99);

-- Verbrauchter Identityhöchstwert oberhalb MAX(EventId), ohne Reseed oder TRUNCATE.
INSERT toolbelt_core.EventLog
    (OccurredAtUtc, RecordedAtUtc, EventName, EventLevel, ExecutionId, CorrelationId,
     SourceDatabaseName, CallerSessionId, CallerXactState, CallerTransactionCount, RemoteSessionId)
OUTPUT inserted.EventId, 'deleted' INTO #tbx_EventRepeat_OwnEvents
VALUES ('2026-05-06T07:08:09.0000001', '2026-05-06T07:08:09.0000002', 'test.repeat.deleted', 'INFO',
        '77777777-9999-9999-9999-999999999999', '77777777-aaaa-aaaa-aaaa-aaaaaaaaaaaa', N'Contoso', 9, 0, 0, 10);
DELETE e FROM toolbelt_core.EventLog AS e
JOIN #tbx_EventRepeat_OwnEvents AS owned ON owned.EventId = e.EventId WHERE owned.Role = 'deleted';
UPDATE #tbx_EventRepeat_State SET LastEventIdentity = IDENT_CURRENT(N'toolbelt_core.EventLog');
IF (SELECT LastEventIdentity FROM #tbx_EventRepeat_State) <= (SELECT MAX(EventId) FROM toolbelt_core.EventLog)
    THROW 52751, N'Der synthetische Event-Identityhöchstwert fehlt.', 1;

-- Nur öffentliche Katalogmutationen. Der fremde eigene Sentinel bleibt deaktiviert.
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName = 'test.event-repeat.sentinel',
     @HandlerSchema = N'toolbelt_core', @HandlerProcedure = N'USP_WriteEventInternal',
     @ParameterMode = 'JSON_PAYLOAD', @PayloadContractJson = N'{"type":"object","synthetic":true}',
     @DefaultTimeoutSeconds = 47, @Description = N'Synthetic sentinel ä ', @ResultTable = N'#EventRepeatWorkTypeResult';
UPDATE #tbx_EventRepeat_State SET SentinelId =
    (SELECT WorkTypeId FROM toolbelt_core.WorkType WHERE WorkTypeName = 'test.event-repeat.sentinel');
DECLARE @SentinelRowVersion binary(8) = (SELECT CONVERT(binary(8), RowVersion) FROM toolbelt_core.WorkType
                                        WHERE WorkTypeName = 'test.event-repeat.sentinel');
EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName = 'test.event-repeat.sentinel',
     @ExpectedRowVersion = @SentinelRowVersion, @DisabledReason = N'Synthetic sentinel disabled 中 ',
     @ResultTable = N'#EventRepeatWorkTypeResult';
DECLARE @EventRowVersion binary(8) = (SELECT CONVERT(binary(8), RowVersion) FROM toolbelt_core.WorkType
                                     WHERE WorkTypeName = 'toolbelt.event-log.write');
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName = 'toolbelt.event-log.write',
     @HandlerSchema = N'toolbelt_core', @HandlerProcedure = N'USP_WriteEventInternal',
     @ParameterMode = 'JSON_PAYLOAD', @PayloadContractJson = N'{"type":"object","synthetic":true}',
     @DefaultTimeoutSeconds = 31, @IsIdempotent = 1, @Description = N'Synthetic pre-repeat drift',
     @AllowUpdate = 1, @ExpectedRowVersion = @EventRowVersion, @ResultTable = N'#EventRepeatWorkTypeResult';
SET @EventRowVersion = (SELECT CONVERT(binary(8), RowVersion) FROM toolbelt_core.WorkType
                       WHERE WorkTypeName = 'toolbelt.event-log.write');
EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName = 'toolbelt.event-log.write',
     @ExpectedRowVersion = @EventRowVersion, @DisabledReason = N'Synthetic pre-repeat disable',
     @ResultTable = N'#EventRepeatWorkTypeResult';

-- Event Log normalisiert keine MS_Description: auch diese Annotationen müssen erhalten bleiben.
EXEC sys.sp_addextendedproperty @name = N'Toolbelt.Test.EventRepeat', @value = 314159,
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core', @level1type = N'TABLE', @level1name = N'EventLog';
EXEC sys.sp_addextendedproperty @name = N'Toolbelt.Test.EventRepeat', @value = N'Synthetic column 中 ',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core', @level1type = N'TABLE', @level1name = N'EventLog',
     @level2type = N'COLUMN', @level2name = N'Message';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Synthetic table ä ',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core', @level1type = N'TABLE', @level1name = N'EventLog';
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Synthetic message 中 ',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core', @level1type = N'TABLE', @level1name = N'EventLog',
     @level2type = N'COLUMN', @level2name = N'Message';
GO
:r ../Tests/Runtime/RepeatCurrent.Capture.sql

UPDATE #tbx_EventRepeat_State SET Phase = 1, DeployStartedAtUtc = SYSUTCDATETIME();
GO
:r Deploy.sql
:r ../Tests/Runtime/RepeatCurrent.Capture.sql
:r ../Tests/Runtime/RepeatCurrent.Assert.sql

UPDATE #tbx_EventRepeat_State SET Phase = 2;
GO
:r Deploy.sql
:r ../Tests/Runtime/RepeatCurrent.Capture.sql
:r ../Tests/Runtime/RepeatCurrent.Assert.sql

-- Regulärer DML-Witness erst nach den beiden unveränderten Event-Snapshots.
INSERT toolbelt_core.EventLog
    (OccurredAtUtc, RecordedAtUtc, EventName, EventLevel, ExecutionId, CorrelationId,
     SourceDatabaseName, CallerSessionId, CallerXactState, CallerTransactionCount, RemoteSessionId)
OUTPUT inserted.EventId, 'next' INTO #tbx_EventRepeat_OwnEvents
VALUES ('2026-06-07T08:09:10.0000001', '2026-06-07T08:09:10.0000002', 'test.repeat.next', 'INFO',
        '77777777-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '77777777-cccc-cccc-cccc-cccccccccccc', N'Contoso', 11, 0, 0, 12);
IF CONVERT(decimal(38,0), SCOPE_IDENTITY()) <> (SELECT LastEventIdentity + 1 FROM #tbx_EventRepeat_State)
    THROW 52757, N'Der Event-Repeat hat den nächsten Identitywert verändert.', 1;

-- Bereinigung nur eigener IDs, Katalogregistrierung und kollisionsgeprüfter Annotationen.
DELETE e FROM toolbelt_core.EventLog AS e JOIN #tbx_EventRepeat_OwnEvents AS owned ON owned.EventId = e.EventId;
IF EXISTS (SELECT 1 FROM toolbelt_core.EventLog AS e JOIN #tbx_EventRepeat_OwnEvents AS owned ON owned.EventId = e.EventId)
    THROW 52758, N'Die eigenen Repeat-Events wurden nicht bereinigt.', 1;
DECLARE @CleanupRowVersion binary(8) = (SELECT CONVERT(binary(8), RowVersion) FROM toolbelt_core.WorkType
                                       WHERE WorkTypeName = 'test.event-repeat.sentinel'
                                         AND WorkTypeId = (SELECT SentinelId FROM #tbx_EventRepeat_State) AND IsEnabled = 0);
IF @CleanupRowVersion IS NULL
    THROW 52758, N'Die eigene Sentinelregistrierung ist nicht mehr eindeutig.', 2;
EXEC toolbelt_core.USP_RemoveWorkType @WorkTypeName = 'test.event-repeat.sentinel',
     @ExpectedRowVersion = @CleanupRowVersion, @AllowDelete = 1, @ResultTable = N'#EventRepeatWorkTypeResult';
IF EXISTS (SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName = 'test.event-repeat.sentinel')
    THROW 52758, N'Die eigene Sentinelregistrierung wurde nicht bereinigt.', 3;
EXEC sys.sp_dropextendedproperty @name = N'Toolbelt.Test.EventRepeat',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core', @level1type = N'TABLE', @level1name = N'EventLog';
EXEC sys.sp_dropextendedproperty @name = N'Toolbelt.Test.EventRepeat',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core', @level1type = N'TABLE', @level1name = N'EventLog',
     @level2type = N'COLUMN', @level2name = N'Message';
EXEC sys.sp_dropextendedproperty @name = N'MS_Description',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core', @level1type = N'TABLE', @level1name = N'EventLog';
EXEC sys.sp_dropextendedproperty @name = N'MS_Description',
     @level0type = N'SCHEMA', @level0name = N'toolbelt_core', @level1type = N'TABLE', @level1name = N'EventLog',
     @level2type = N'COLUMN', @level2name = N'Message';
IF @@TRANCOUNT <> 0 THROW 52758, N'Der Event-Repeat hinterließ eine Transaktion.', 4;
IF XACT_STATE() <> 0 THROW 52758, N'Der Event-Repeat hinterließ einen Transaktionszustand.', 5;
DROP TABLE #EventRepeatWorkTypeResult;
DROP TABLE #tbx_EventRepeat_WorkType;
DROP TABLE #tbx_EventRepeat_Snapshot;
DROP TABLE #tbx_EventRepeat_OwnEvents;
DROP TABLE #tbx_EventRepeat_State;
PRINT N'Event Log populated repeat (two cycles): successful';
GO
