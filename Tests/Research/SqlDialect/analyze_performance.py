"""Bindet lokale Perfberichte und trennt Plan-/Ergebnis- von Zeitnachweisen.

Messwerte und Rohpläne bleiben unter .runtime/. Dies ist kein allgemeines
Diagnosemodul; die zulässige Matrix ist der feste Research-Workload.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import xml.etree.ElementTree as ET

from performance_cases import build, stability
from run_native_databricks import digest, runtime_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', type=Path, required=True)
    args = parser.parse_args()
    directory = runtime_path(args.directory)
    own = Path(__file__).parent
    fixtures = build()
    expected = {d['events']: d['expected'] for d in fixtures['datasets']}
    reports, readings = {}, []
    for engine, filename, count in [('sql_server', 'sql-server.json', 34), ('spark', 'spark.json', 20)]:
        report = json.loads((directory / filename).read_text(encoding='utf-8-sig'))
        if report['status'] != 'validated' or len(report['cases']) != count:
            raise RuntimeError('INCOMPLETE_NATIVE_MATRIX')
        for name, wanted in report['source_hashes'].items():
            if digest(own / name).lower() != wanted.lower():
                raise RuntimeError('SOURCE_BINDING_MISMATCH')
        if engine == 'sql_server':
            helper = own.parents[1] / 'CI/run-lab-local.ps1'
            if digest(helper).lower() != report['lab_helper_hash'].lower():
                raise RuntimeError('LAB_HELPER_BINDING_MISMATCH')
        if len(report['unsafe_controls']) != 2 or any(c['status'] != 'validated' for c in report['unsafe_controls']):
            raise RuntimeError('UNSAFE_CONTROL_MISSING')
        seen = set()
        for case in report['cases']:
            key = (case['events'], case['layout'], case['name'])
            if key in seen or case['status'] != 'validated':
                raise RuntimeError('DUPLICATE_OR_FAILED_CASE')
            seen.add(key)
            scenario = case['name'].split('/')[0]
            wanted = expected[case['events']][scenario]
            if case['rows'] != wanted['rows'] or case['result_sha256'] != wanted['sha256']:
                raise RuntimeError('RESULT_BINDING_MISMATCH')
            plan = runtime_path(directory / case['plan_file'])
            if not plan.is_relative_to(directory) or not plan.is_file():
                raise RuntimeError('PLAN_MISSING_OR_OUTSIDE_RUN')
            assessment = stability(case['batches'])
            record = dict(engine=engine, events=case['events'], layout=case['layout'], name=case['name'],
                          result_status='validated', timing=assessment, plan_file=case['plan_file'], plan_sha256=digest(plan))
            if engine == 'sql_server':
                ns = {'s': 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'}
                root = ET.parse(plan).getroot()
                operators = []
                for op in root.findall('.//s:RelOp', ns):
                    counters = op.findall('./s:RunTimeInformation/s:RunTimeCountersPerThread', ns)
                    operators.append(dict(operator=op.get('PhysicalOp'), logical=op.get('LogicalOp'),
                        actual_rows=sum(float(c.get('ActualRows', 0)) for c in counters),
                        rows_read=sum(float(c.get('ActualRowsRead', 0)) for c in counters),
                        logical_reads=sum(float(c.get('ActualLogicalReads', 0)) for c in counters),
                        executions=sum(float(c.get('ActualExecutions', 0)) for c in counters)))
                if not root.findall('.//s:RunTimeCountersPerThread', ns):
                    raise RuntimeError('ACTUAL_PLAN_COUNTERS_MISSING')
                record['operators'] = operators
                record['query_time_stats'] = [node.attrib for node in root.findall('.//s:QueryTimeStats', ns)]
                record['warnings'] = case['warnings']
            else:
                text = plan.read_text(encoding='utf-8').split('\n\n', 1)[0]
                if 'AdaptiveSparkPlan' in text and not case['aqe_final']:
                    raise RuntimeError('AQE_PLAN_NOT_FINAL')
                record['operators'] = case['plan_operators']
            readings.append(record)
        reports[engine] = dict(report_sha256=digest(directory / filename), result_cases=count,
            stable_cases=sum(stability(c['batches'])['status'] == 'validated' for c in report['cases']),
            unstable_cases=sum(stability(c['batches'])['status'] != 'validated' for c in report['cases']),
            unsafe_controls=2)
    # Nur innerhalb einer Engine und eines Datasets vergleichen. Zwei stabile
    # Serien und getrennte Batchmedianbereiche sind Mindestvoraussetzungen.
    pairs = []

    def add_pair(baseline, alternative, scope):
        a, b = baseline['timing'], alternative['timing']
        valid = a['status'] == b['status'] == 'validated'
        direction = 'not qualified'
        if valid:
            direction = 'no separated batch ranges'
            if max(b['batch_medians_ms']) < min(a['batch_medians_ms']):
                direction = 'alternative lower client time'
            elif max(a['batch_medians_ms']) < min(b['batch_medians_ms']):
                direction = 'baseline lower client time'
        pairs.append(dict(engine=baseline['engine'], events=baseline['events'], scope=scope,
            baseline=baseline['layout'] + '/' + baseline['name'],
            alternative=alternative['layout'] + '/' + alternative['name'],
            timing_status='validated' if valid else 'not executed', direction=direction,
            observed_ratio=a['median_ms']/b['median_ms'] if valid else None))

    for engine in ('sql_server', 'spark'):
        for size in expected:
            group = [r for r in readings if r['engine'] == engine and r['events'] == size]
            for scenario in ('selective', 'broad', 'cutoff', 'global'):
                primary = 'parent_index' if engine == 'sql_server' else 'cached'
                items = [r for r in group if r['layout'] == primary and r['name'].startswith(scenario + '/')]
                baseline = next(r for r in items if r['name'].endswith('/correlated'))
                for alternative in items:
                    if alternative is baseline:
                        continue
                    add_pair(baseline, alternative, scenario)
            if engine == 'sql_server':
                for name, layout_a, layout_b in [('selective/correlated', 'heap', 'parent_index'),
                                                ('global/correlated', 'parent_index', 'global_index')]:
                    a = next(r for r in group if r['name'] == name and r['layout'] == layout_a)
                    b = next(r for r in group if r['name'] == name and r['layout'] == layout_b)
                    add_pair(a, b, 'index/' + name)
    stable_count = sum(r['timing']['status'] == 'validated' for r in readings)
    result = dict(generated_at=datetime.now(timezone.utc).isoformat(), source_hash=digest(Path(__file__)),
                  reports=reports, cases=readings, pairs=pairs, databricks_execution='not executed',
                  cross_engine_speed_ranking='not applicable', performance_qualification=(
                      'validated' if stable_count == len(readings) else 'partially validated' if stable_count else 'not executed'))
    (directory / 'assessment.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    lines = ['# Lokale Performance-Messwerte', '', 'Nicht versionieren. Nur innerhalb einer Engine/Größe vergleichen.', '',
        'SQL Server: RPC/Reader einschließlich Kanonisierung; Spark: Planung/collect. Warmprofile, keine Hardwaregleichheit.', '',
        'Baseline: APPLY/LATERAL; im global-Szenario direktes TOP/LIMIT. Indexpaare ändern nur das Layout derselben Query.', '',
        '| Engine | Events | Layout | Variante | Median ms | Batchdrift % | Zeitnachweis |', '|---|---:|---|---|---:|---:|---|']
    for r in readings:
        timing = r['timing']
        lines.append(f"| {r['engine']} | {r['events']} | {r['layout']} | {r['name']} | {timing['median_ms']:.3f} | {timing['drift_percent']:.1f} | {timing['status']} |")
    lines.extend(['', '## Vergleich innerhalb derselben Engine', '', '| Engine | Events | Szenario | Alternative | Richtung | Quotient Baseline/Alternative |', '|---|---:|---|---|---|---:|'])
    for pair in pairs:
        ratio = f"{pair['observed_ratio']:.3f}" if pair['observed_ratio'] is not None else '—'
        lines.append(f"| {pair['engine']} | {pair['events']} | {pair['scope']} | {pair['alternative']} | {pair['direction']} | {ratio} |")
    (directory / 'measurements.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(json.dumps(reports))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
