#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parents[2]
required=[
 'Source/EventLog.sql','Source/VW_Events.sql','Source/USP_WriteEventInternal.sql','Source/USP_WriteEvent.sql','Source/USP_DeleteEventsBefore.sql',
 'Deployment/Deploy.sql','Deployment/Uninstall.sql','README.md','Documentation/EVENT_LOG_OBJECTS.md','Tests/EVENT_LOG_CONTRACT_TEST_MATRIX.md','Tests/README.md',
 'Tests/Runtime/EventLog.Contract.sql','Tests/Runtime/Lifecycle.Contract.sql','Tests/Runtime/Concurrency.Contract.sql','Tests/Runtime/Concurrency.Verify.sql','Tests/Runtime/Central.Contract.sql','module.yaml']
missing=[p for p in required if not (root/p).is_file()]
if missing: raise SystemExit('Fehlende Artefakte: '+', '.join(missing))
text='\n'.join((root/p).read_text(encoding='utf-8') for p in required if p.startswith('Source/') or p.startswith('Deployment/'))
for marker in ('CREATE TABLE [toolbelt_core].[EventLog]','PK_EventLog','IX_EventLog_OccurredAtUtc_EventId','USP_WriteEventInternal','USP_WriteEvent','USP_DeleteEventsBefore','toolbelt.event-log.write','@SuppressResult = 1','USP_RemoveWorkType','AllowDataLoss'):
    if marker not in text: raise SystemExit('Vertragsmarker fehlt: '+marker)
for forbidden in ('sp_addlinkedserver','sp_addlinkedsrvlogin','@rmtpassword','TRUSTWORTHY ON'):
    if forbidden.lower() in text.lower(): raise SystemExit('Verbotener Provider-/Security-Marker: '+forbidden)
print('Event Log statische Vertragsprüfung: erfolgreich')
