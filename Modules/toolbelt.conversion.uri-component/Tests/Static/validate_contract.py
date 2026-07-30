#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parents[2]
required=('Source/TVF_UriComponentEncode.sql','Source/TVF_UriComponentDecode.sql','Source/SVF_UriComponentEncode.sql','Source/SVF_UriComponentDecode.sql','Deployment/Deploy.sql','Deployment/Uninstall.sql','README.md','module.yaml','Tests/Runtime/UriComponent.Contract.sql','Tests/Runtime/Lifecycle.Contract.sql','Tests/Runtime/Central.Contract.sql')
missing=[p for p in required if not (root/p).is_file()]
if missing: raise SystemExit('Fehlende Artefakte: '+', '.join(missing))
tvf=''.join((root/p).read_text(encoding='utf-8') for p in required[:2])
svf=''.join((root/p).read_text(encoding='utf-8') for p in required[2:4])
if tvf.count('RETURNS TABLE')!=2 or 'Latin1_General_100_BIN2_UTF8' not in tvf or 'TVF_UriComponentEncode' not in svf or 'TVF_UriComponentDecode' not in svf: raise SystemExit('URI-Komponentenvertrag fehlt.')
print('URI Component statische Vertragsprüfung: erfolgreich')
