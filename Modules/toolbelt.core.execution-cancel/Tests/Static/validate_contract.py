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
    'Tests/Runtime/Lifecycle.Contract.sql', 'Tests/Runtime/Central.Contract.sql',
    'Tests/Runtime/RepeatCurrent.Contract.sql', 'Tests/Runtime/RepeatCurrent.Capture.sql',
    'Tests/Runtime/RepeatCurrent.Assert.sql', 'Tests/Runtime/RepeatCurrent.Negative.sql',
    'Tests/Runtime/RepeatCurrent.NormalizeNegativeVersion.sql', 'module.yaml'
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

repeat = (root / 'Tests/Runtime/RepeatCurrent.Contract.sql').read_text('utf-8')
capture = (root / 'Tests/Runtime/RepeatCurrent.Capture.sql').read_text('utf-8')
assertion = (root / 'Tests/Runtime/RepeatCurrent.Assert.sql').read_text('utf-8')
for include, count in ((':r Deploy.sql', 2),
                       (':r ../Tests/Runtime/RepeatCurrent.Capture.sql', 3),
                       (':r ../Tests/Runtime/RepeatCurrent.Assert.sql', 2)):
    if repeat.count(include) != count:
        raise SystemExit('Befüllter Repeat muss zwei echte Deploys mit identischen Orakeln ausführen.')
for marker in ('ExecutionId', 'RequestedAtUtc', 'CONVERT(varbinary(max), RequestedBy)',
               'CONVERT(varbinary(max), CancellationReason)', 'CONVERT(binary(8), RowVersion)',
               'RequestedByPrincipalId', 'CONVERT(varbinary(max), RequestedByPrincipalSid)',
               'CONVERT(binary(8), RequestedByPrincipalCreatedAt)',
               'sys.objects', 'sys.schemas', 'sys.tables', 'sys.columns', 'sys.indexes',
               'sys.index_columns', 'sys.key_constraints', 'sys.default_constraints',
               'sys.check_constraints', 'sys.foreign_keys', 'sys.foreign_key_columns',
               'sys.triggers', 'sys.database_permissions', 'sys.extended_properties'):
    if marker not in capture:
        raise SystemExit('Cancellation-Repeat-Snapshot fehlt: ' + marker)
if assertion.count('EXCEPT') != 2 or '@@TRANCOUNT <> 0' not in assertion or 'XACT_STATE() <> 0' not in assertion:
    raise SystemExit('Repeat muss bidirektional vergleichen und den Sessionabschluss prüfen.')
negative = (root / 'Tests/Runtime/RepeatCurrent.Negative.sql').read_text('utf-8')
normalization = (root / 'Tests/Runtime/RepeatCurrent.NormalizeNegativeVersion.sql').read_text('utf-8')
if repeat.count(':r ../Tests/Runtime/RepeatCurrent.Negative.sql') != 1:
    raise SystemExit('Drei isolierte Principalgegenproben müssen vor den echten Deploys laufen.')
if 'SET QUOTED_IDENTIFIER ON;\nGO' not in repeat:
    raise SystemExit('XML-Gegenproben benötigen expliziten QUOTED_IDENTIFIER vor dem nächsten Batch.')
for include in ('RepeatCurrent.Capture.sql', 'RepeatCurrent.NormalizeNegativeVersion.sql', 'RepeatCurrent.Assert.sql'):
    if negative.count(':r ../Tests/Runtime/' + include) != 3:
        raise SystemExit('Jede Principalgegenprobe benötigt originales Capture und Assert mit isolierter Rowversion.')
for column in ('RequestedByPrincipalId', 'RequestedByPrincipalSid', 'RequestedByPrincipalCreatedAt'):
    if f'SET {column} =' not in negative:
        raise SystemExit('Principalgegenprobe fehlt: ' + column)
if ('ERROR_NUMBER() = 52743 AND ERROR_STATE() = 1' not in assertion
        or 'ROLLBACK TRANSACTION' not in assertion or 'THROW 52747' not in assertion
        or 'replace value of' not in normalization or 'RowVersionBytes/text()' not in normalization
        or 'sql:variable("@Version")' not in normalization):
    raise SystemExit('Negative müssen das exakte Originalorakel trotz kompensierter Rowversion beweisen.')
if repeat.count("sys.sp_addextendedproperty @name = N'MS_Description'") != 2 or repeat.count(
        "sys.sp_dropextendedproperty @name = N'MS_Description'") != 2:
    raise SystemExit('Repeat muss eigene Tabellen- und Spaltenbeschreibungen prüfen und bereinigen.')
print('Execution Cancellation statische Vertragsprüfung: erfolgreich')
