#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parents[2]
required=('Source/TVF_TrimDirectionalNvarchar.sql','Source/TVF_TrimDirectionalVarchar.sql','Deployment/Deploy.sql','Deployment/Uninstall.sql','README.md','module.yaml','Tests/Runtime/DirectionalTrim.Contract.sql')
missing=[p for p in required if not (root/p).is_file()]
if missing: raise SystemExit('Fehlende Artefakte: '+', '.join(missing))
text=''.join((root/p).read_text(encoding='utf-8') for p in required[:2])
if text.count('RETURNS TABLE')!=2 or 'TVF_GenerateSeriesBigInt' not in text: raise SystemExit('Directional-TRIM-Vertrag fehlt.')
print('Directional TRIM statische Vertragsprüfung: erfolgreich')
