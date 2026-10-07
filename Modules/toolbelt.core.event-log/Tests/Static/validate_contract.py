#!/usr/bin/env python3
from pathlib import Path
import re
root=Path(__file__).resolve().parents[2]
required=[
 'Source/EventLog.sql','Source/VW_Events.sql','Source/USP_WriteEventInternal.sql','Source/USP_WriteEvent.sql','Source/USP_DeleteEventsBefore.sql',
 'Deployment/Deploy.sql','Deployment/Uninstall.sql','README.md','Documentation/EVENT_LOG_OBJECTS.md','Tests/EVENT_LOG_CONTRACT_TEST_MATRIX.md','Tests/README.md',
 'Tests/Runtime/EventLog.Contract.sql','Tests/Runtime/Lifecycle.Contract.sql','Tests/Runtime/Concurrency.Contract.sql','Tests/Runtime/Concurrency.Verify.sql','Tests/Runtime/Central.Contract.sql',
 'Tests/Runtime/RepeatCurrent.Contract.sql','Tests/Runtime/RepeatCurrent.Capture.sql','Tests/Runtime/RepeatCurrent.Assert.sql','module.yaml']
missing=[p for p in required if not (root/p).is_file()]
if missing: raise SystemExit('Fehlende Artefakte: '+', '.join(missing))
text='\n'.join((root/p).read_text(encoding='utf-8') for p in required if p.startswith('Source/') or p.startswith('Deployment/'))
for marker in ('CREATE TABLE [toolbelt_core].[EventLog]','PK_EventLog','IX_EventLog_OccurredAtUtc_EventId','USP_WriteEventInternal','USP_WriteEvent','USP_DeleteEventsBefore','toolbelt.event-log.write','@SuppressResult = 1','USP_RemoveWorkType','AllowDataLoss'):
    if marker not in text: raise SystemExit('Vertragsmarker fehlt: '+marker)
for forbidden in ('sp_addlinkedserver','sp_addlinkedsrvlogin','@rmtpassword','TRUSTWORTHY ON'):
    if forbidden.lower() in text.lower(): raise SystemExit('Verbotener Provider-/Security-Marker: '+forbidden)
repeat=(root/'Tests/Runtime/RepeatCurrent.Contract.sql').read_text(encoding='utf-8')
capture=(root/'Tests/Runtime/RepeatCurrent.Capture.sql').read_text(encoding='utf-8')
assertions=(root/'Tests/Runtime/RepeatCurrent.Assert.sql').read_text(encoding='utf-8')
for include, count in ((':r Deploy.sql',2),(':r ../Tests/Runtime/RepeatCurrent.Capture.sql',3),(':r ../Tests/Runtime/RepeatCurrent.Assert.sql',2)):
    if repeat.count(include) != count: raise SystemExit('Event-Repeat-Includefolge ist unvollständig: '+include)
projection=capture.split("'events'",1)[1].split('FROM toolbelt_core.EventLog',1)[0]
event_columns=('EventId','OccurredAtUtc','RecordedAtUtc','EventName','EventLevel','Category','Message','DataJson','ExecutionId','CorrelationId','Actor','Tenant','SourceDatabaseName','SourceSchemaName','SourceObjectName','CallerSessionId','CallerXactState','CallerTransactionCount','RemoteSessionId','ErrorNumber','ErrorSeverity','ErrorState','ErrorProcedure','ErrorLine')
for column in event_columns:
    if not re.search(r'\b'+column+r'\b',projection): raise SystemExit('Event-Repeat-Snapshotspalte fehlt: '+column)
for marker in ('ELEMENTS XSINIL','CONVERT(binary(8), RowVersion)','sys.columns','sys.identity_columns','sys.indexes','sys.index_columns','sys.key_constraints','sys.default_constraints','sys.check_constraints','sys.database_permissions','SQL_VARIANT_PROPERTY','sys.sql_modules','sys.parameters',"'other-work-types'","'work-type-stable'","'work-type-current'"):
    if marker not in capture: raise SystemExit('Event-Repeat-Snapshotmarker fehlt: '+marker)
for marker in ('@AllowUpdate = 1','USP_DisableWorkType','USP_RemoveWorkType',"@ResultTable = N'#EventRepeatWorkTypeResult'",'IDENT_CURRENT', 'SCOPE_IDENTITY()',"N'MS_Description'", "@value = 314159", "'deleted'", "'next'"):
    if marker not in repeat: raise SystemExit('Event-Repeat-Setup/Cleanupmarker fehlt: '+marker)
for marker in ('@Phase = 1','@Phase = 2','current_row.RowVersion <> previous_row.RowVersion','current_row.IsEnabled = 1','current_row.DisabledAtUtc IS NULL','current_row.ModifiedAtUtc >= state_row.DeployStartedAtUtc','IF XACT_STATE() <> 0'):
    if marker not in assertions: raise SystemExit('Event-Repeat-Orakel fehlt: '+marker)
if assertions.count('EXCEPT') != 4: raise SystemExit('Event-Repeat benötigt beide symmetrischen Snapshotvergleiche')
fixtures=repeat+'\n'+capture+'\n'+assertions
if re.search(r'\b(?:INSERT(?:\s+INTO)?|UPDATE|DELETE(?:\s+FROM)?|TRUNCATE\s+TABLE)\s+toolbelt_core\.WorkType\b',fixtures,re.I):
    raise SystemExit('Event-Repeat darf WorkType nur über öffentliche APIs mutieren')
for forbidden in ('sp_addlinkedserver','sp_addlinkedsrvlogin','sp_configure','TRUSTWORTHY ON','GRANT ','CREATE PROCEDURE','CREATE OR ALTER PROCEDURE','DBCC CHECKIDENT','TRUNCATE TABLE'):
    if forbidden.lower() in fixtures.lower(): raise SystemExit('Verbotene Event-Repeat-Scopeerweiterung: '+forbidden)
manifest=(root/'module.yaml').read_text(encoding='utf-8')
for key, filename in (('repeat_current','Contract'),('repeat_capture','Capture'),('repeat_assert','Assert')):
    if f'{key}: "Tests/Runtime/RepeatCurrent.{filename}.sql"' not in manifest:
        raise SystemExit('Event-Repeat-Manifestkopplung fehlt: '+key)
print('Event Log statische Vertragsprüfung: erfolgreich')
