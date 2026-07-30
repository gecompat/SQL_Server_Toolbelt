#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parents[2]
required=('Source/TVF_CalendarDifference.sql','Deployment/Deploy.sql','Deployment/Uninstall.sql','README.md','Documentation/TVF_CalendarDifference.md','Tests/Runtime/CalendarDifference.Contract.sql','Tests/Runtime/Lifecycle.Contract.sql','Tests/Runtime/Central.Contract.sql','module.yaml')
missing=[p for p in required if not (root/p).is_file()]
if missing: raise SystemExit('Fehlende Artefakte: '+', '.join(missing))
text=(root/'Source/TVF_CalendarDifference.sql').read_text(encoding='utf-8')
if 'RETURNS TABLE' not in text or 'DATEADD' not in text: raise SystemExit('Calendar-Difference-Vertrag fehlt.')
print('Calendar Difference statische Vertragsprüfung: erfolgreich')
