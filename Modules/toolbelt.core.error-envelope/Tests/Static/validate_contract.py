#!/usr/bin/env python3
from pathlib import Path
root = Path(__file__).resolve().parents[2]
required = [
    'Source/USP_CaptureErrorEnvelope.sql', 'Deployment/Deploy.sql',
    'Deployment/Uninstall.sql', 'README.md',
    'Documentation/USP_CaptureErrorEnvelope.md',
    'Tests/Runtime/ErrorEnvelope.Contract.sql',
    'Tests/Runtime/Lifecycle.Contract.sql', 'Tests/Runtime/Central.Contract.sql',
    'Tests/ERROR_ENVELOPE_CONTRACT_TEST_MATRIX.md', 'module.yaml'
]
missing = [p for p in required if not (root / p).is_file()]
if missing:
    raise SystemExit('Fehlende Artefakte: ' + ', '.join(missing))
source = (root / 'Source/USP_CaptureErrorEnvelope.sql').read_text('utf-8')
for marker in ('CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_CaptureErrorEnvelope]',
               '@ResultTable', '@KeepData', '@Hilfe', 'SESSION_CONTEXT',
               'ENGINE', 'TOOLBELT', 'USER', 'USP_PrepareResultTable'):
    if marker not in source:
        raise SystemExit('Vertragsmarker fehlt: ' + marker)
print('Error Envelope statische Vertragsprüfung: erfolgreich')
