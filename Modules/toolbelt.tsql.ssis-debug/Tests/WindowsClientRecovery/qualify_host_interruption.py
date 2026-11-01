"""Echte harte Prozess-/Pipeunterbrechung am gebundenen portablen Exporthost.

Der reale Host blockiert beim Schreiben einer großen synthetischen Ausgabe.
Erst beobachtete Ausgabebytes erlauben den Eingriff; keine Testhooks im Produkt.
Nur eigene Popen-Handles werden beendet. Teiltransport ist niemals ein Ergebnis.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import platform
import queue
import subprocess
import sys
import threading

MODES = ("model", "bundle", "iteration-bundle", "scope-bundle", "pipeline-bundle")
MODULE = "Modules/toolbelt.tsql.ssis-debug/"
METHOD = MODULE + "Tests/WindowsClientRecovery/qualify_host_interruption.py"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def fixture():
    # Feste, unabhängige Objektzahl; Größe erzeugt echte Pipe-Backpressure.
    tasks = ''.join(f'<DTS:Executable DTS:ObjectName="SyntheticTask{i}" '
                    f'DTS:ExecutableType="STOCK:SEQUENCE" DTS:refId="Task{i}" />'
                    for i in range(2000))
    return ('<DTS:Executable xmlns:DTS="www.microsoft.com/SqlServer/Dts" '
            'DTS:ObjectName="SyntheticRecoveryPackage" DTS:ExecutableType="Microsoft.Package" '
            'DTS:refId="Package" DTS:ProtectionLevel="0">'
            '<DTS:Property DTS:Name="PackageFormatVersion">8</DTS:Property>'
            '<DTS:Executables>' + tasks + '</DTS:Executables></DTS:Executable>').encode()


def reserve(budget, interrupted):
    value = json.loads(budget.read_text(encoding="utf-8-sig"))
    if datetime.now(timezone.utc) >= datetime.fromisoformat(value['ceilingUtc'].replace('Z', '+00:00')):
        raise ValueError("SSIS_RECOVERY_TIME_BUDGET")
    if value['nativeUsed'] >= value['maximumNativeCaseOrAuditInvocations']:
        raise ValueError("SSIS_RECOVERY_NATIVE_BUDGET")
    if interrupted and value['hardInterruptionUsed'] >= value['maximumHardInterruptionCases']:
        raise ValueError("SSIS_RECOVERY_INTERRUPTION_BUDGET")
    value['nativeUsed'] += 1
    value['hardInterruptionUsed'] += int(interrupted)
    budget.write_text(json.dumps(value, indent=2) + '\n', encoding="utf-8")


def read_prefix(process):
    result = queue.Queue(maxsize=1)
    def read():
        try:
            result.put(process.stdout.read(64))
        except Exception as error:
            result.put(error)
    reader = threading.Thread(target=read, daemon=True)
    reader.start()
    try:
        value = result.get(timeout=30)
    except queue.Empty as error:
        raise ValueError("SSIS_RECOVERY_OUTPUT_NOT_OBSERVED") from error
    if isinstance(value, Exception):
        raise value
    if len(value) != 64 or process.poll() is not None:
        raise ValueError("SSIS_RECOVERY_NO_ACTIVE_PRODUCER")
    return value, reader


def qualify(root, host, dotnet, output, budget):
    if platform.system() != "Windows":
        raise ValueError("SSIS_RECOVERY_WINDOWS_REQUIRED")
    runtime = (root / '.runtime').resolve()
    if not output.resolve().is_relative_to(runtime) or output.exists():
        raise ValueError("SSIS_RECOVERY_PRIVATE_NEW_OUTPUT_REQUIRED")
    sys.path.insert(0, str(root / 'Scripts/Release'))
    import validate_ssis_linux_export
    validate_ssis_linux_export.validate(root)
    record = json.loads((root / (MODULE + 'Tests/Qualification/ExportHost.Linux.20261101.json')).read_text())
    expected = record['runs'][0]
    if sha(host.read_bytes()) != expected['host_sha256']:
        raise ValueError("SSIS_RECOVERY_QUALIFIED_HOST_REQUIRED")
    pins = dict(expected['source_sha256'])
    pins[METHOD] = sha((root / METHOD).read_bytes())
    output.mkdir()
    package = output / 'Synthetic-Ä-恢复.dtsx'
    data = fixture()
    package.write_bytes(data)
    cases = []
    report = {'contract': 'ssis-host-hard-interruption/1', 'result': 'RUNNING',
              'platform': 'Windows', 'source_sha256': pins, 'host_sha256': expected['host_sha256'],
              'fixture_sha256': sha(data), 'case_count': 0, 'assertions': 0, 'cases': cases}
    destination = output / 'result.private.json'
    def save():
        report['case_count'] = len(cases)
        report['assertions'] = sum(x['assertions'] for x in cases)
        destination.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    save()
    env = dict(os.environ, DOTNET_CLI_TELEMETRY_OPTOUT='1', DOTNET_MULTILEVEL_LOOKUP='0')
    try:
        for mode in MODES:
            args = [str(dotnet), str(host)] + ([] if mode == 'model' else ['--' + mode]) + [str(package)]
            reserve(budget, False)
            baseline = subprocess.run(args, capture_output=True, env=env, timeout=40)
            if baseline.returncode or baseline.stderr:
                raise ValueError('SSIS_RECOVERY_BASELINE_FAILED_' + mode)
            parsed = json.loads(baseline.stdout)
            model = parsed if mode == 'model' else parsed['model']
            if (len(model['nodes']) != 2001 or len(baseline.stdout) < 131072 or
                    model['source']['packageSha256'] != sha(data) or
                    model['producer']['buildSha256'] != expected['host_sha256']):
                raise ValueError('SSIS_RECOVERY_BASELINE_ORACLE_' + mode)
            for kind in ('process-termination', 'pipe-disconnection'):
                reserve(budget, True)
                checks = 0
                def check(value, name):
                    nonlocal checks
                    if not value:
                        raise ValueError('SSIS_RECOVERY_' + name)
                    checks += 1
                with subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env) as process:
                    try:
                        prefix, reader = read_prefix(process)
                        check(prefix == baseline.stdout[:64], 'REAL_OUTPUT_PREFIX')
                        check(process.poll() is None, 'PRODUCER_ALIVE_BEFORE_INTERRUPT')
                        if kind == 'process-termination':
                            process.kill()
                            code = process.wait(timeout=10)
                            partial = prefix + process.stdout.read()
                            check(code != 0, 'HARD_TERMINATION_NONZERO')
                        else:
                            process.stdout.close()
                            code = process.wait(timeout=10)
                            partial = prefix
                        reader.join(timeout=2)
                        check(not reader.is_alive(), 'READER_FINISHED')
                        process.stderr.read()
                    finally:
                        if process.poll() is None:
                            process.kill()
                            process.wait(timeout=10)
                check(len(partial) < len(baseline.stdout), 'INCOMPLETE_TRANSPORT_OBSERVED')
                try:
                    json.loads(partial)
                except (ValueError, UnicodeError):
                    checks += 1
                else:
                    raise ValueError('SSIS_RECOVERY_PARTIAL_ACCEPTED')
                check(sha(package.read_bytes()) == sha(data), 'INPUT_UNCHANGED')
                reserve(budget, False)
                recovered = subprocess.run(args, capture_output=True, env=env, timeout=40)
                check(recovered.returncode == 0 and not recovered.stderr, 'FRESH_PROCESS_SUCCEEDED')
                check(recovered.stdout == baseline.stdout, 'FRESH_OUTPUT_BYTE_IDENTICAL')
                check(json.loads(recovered.stdout) == parsed, 'FRESH_MODEL_IDENTICAL')
                case = {'mode': mode, 'interruption': kind, 'result': 'PASS', 'assertions': checks,
                        'interrupted_exit_code': code, 'complete_output_sha256': sha(baseline.stdout),
                        'partial_json_rejected': True, 'fresh_output_identical': True, 'input_unchanged': True}
                cases.append(case)
                save()
        if any(sha((root / p).read_bytes()) != h for p, h in pins.items()):
            raise ValueError('SSIS_RECOVERY_INPUT_DRIFT')
        report.update(result='PASS', date=datetime.now(timezone.utc).date().isoformat(),
                      child_processes_started=25, sql_executed=False)
        save()
    except BaseException:
        report['result'] = 'FAILED'
        save()
        raise
    print(f"SSIS_HOST_HARD_INTERRUPTION_PASS cases={len(cases)} assertions={report['assertions']}")


if __name__ == '__main__':
    cli = argparse.ArgumentParser(description=__doc__)
    for arg in ('root', 'host', 'dotnet', 'output', 'budget'):
        cli.add_argument('--' + arg, type=Path, required=True)
    args = cli.parse_args()
    qualify(args.root.resolve(), args.host.resolve(), args.dotnet.resolve(), args.output.resolve(), args.budget.resolve())
