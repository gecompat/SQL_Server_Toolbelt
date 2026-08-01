#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[2]
required = [
    'Source/WorkType.sql',
    'Source/VW_WorkTypes.sql',
    'Source/USP_RegisterWorkType.sql',
    'Source/USP_DisableWorkType.sql',
    'Source/USP_ResolveWorkType.sql',
    'Deployment/Deploy.sql',
    'Deployment/Uninstall.sql',
    'README.md',
    'Documentation/WORK_TYPE_OBJECTS.md',
    'Tests/WORK_TYPE_CONTRACT_TEST_MATRIX.md',
    'Tests/README.md',
    'Tests/Runtime/WorkType.Contract.sql',
    'Tests/Runtime/Concurrency.Contract.sql',
    'Tests/Runtime/Concurrency.Verify.sql',
    'Tests/Runtime/Lifecycle.Contract.sql',
    'Tests/Runtime/Central.Contract.sql',
    'module.yaml',
]
missing = [path for path in required if not (root / path).is_file()]
if missing:
    raise SystemExit('Fehlende Artefakte: ' + ', '.join(missing))

source = '\n'.join(
    (root / path).read_text(encoding='utf-8')
    for path in required
    if path.startswith('Source/')
)
for marker in (
    'CREATE TABLE [toolbelt_core].[WorkType]',
    'PK_WorkType',
    'UQ_WorkType_WorkTypeName',
    'IX_WorkType_IsEnabled_WorkTypeName',
    'USP_RegisterWorkType',
    'USP_DisableWorkType',
    'USP_ResolveWorkType',
    'VW_WorkTypes',
    'JSON_PAYLOAD',
    '@ExpectedRowVersion',
    'HAS_PERMS_BY_NAME',
    'USP_PrepareResultTable',
):
    if marker not in source:
        raise SystemExit('Vertragsmarker fehlt: ' + marker)

if 'sp_executesql' in (root / 'Source/WorkType.sql').read_text(encoding='utf-8'):
    raise SystemExit('Die persistente Tabelle darf keinen ausführbaren SQL-Text enthalten.')

print('Work Type statische Vertragsprüfung: erfolgreich')
