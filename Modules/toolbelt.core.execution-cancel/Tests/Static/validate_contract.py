#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[2]
required = [
    'Source/ExecutionCancellation.sql', 'Source/TVF_ExecutionCancellationStatus.sql',
    'Source/SVF_IsCancellationRequested.sql', 'Source/USP_RequestExecutionCancellation.sql',
    'Deployment/Deploy.sql', 'Deployment/Uninstall.sql', 'README.md',
    'Documentation/EXECUTION_CANCELLATION_OBJECTS.md',
    'Tests/EXECUTION_CANCELLATION_CONTRACT_TEST_MATRIX.md', 'Tests/README.md',
    'Tests/Runtime/ExecutionCancellation.Contract.sql', 'Tests/Runtime/Concurrency.Contract.sql',
    'Tests/Runtime/Lifecycle.Contract.sql', 'Tests/Runtime/Central.Contract.sql', 'module.yaml'
]
missing = [path for path in required if not (root / path).is_file()]
if missing:
    raise SystemExit('Fehlende Artefakte: ' + ', '.join(missing))
source = '\n'.join((root / path).read_text(encoding='utf-8') for path in required if path.startswith('Source/'))
for marker in ('ExecutionCancellation', 'PK_ExecutionCancellation', 'TVF_ExecutionCancellationStatus',
               'SVF_IsCancellationRequested', 'USP_RequestExecutionCancellation', 'UPDLOCK, HOLDLOCK',
               '@@TRANCOUNT <> 0', '52600', 'Toolbelt.ModuleId'):
    if marker not in source and marker not in (root / 'Deployment/Deploy.sql').read_text(encoding='utf-8'):
        raise SystemExit('Vertragsmarker fehlt: ' + marker)
if 'KILL' in source:
    raise SystemExit('Der portable Cancellation-Kern darf kein KILL enthalten.')
print('Execution Cancellation statische Vertragsprüfung: erfolgreich')
