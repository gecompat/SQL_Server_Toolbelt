"""Begrenzte lokale Spark-Performanceversuche für feste SQL-Alternativen.

Ausgabe nur unter .runtime/; keine Databricks- oder plattformübergreifende
Leistungszusage. Ergebnisprüfung ist unabhängig von den gemessenen Abfragen.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import logging
from pathlib import Path
from threading import Timer
from time import perf_counter

from performance_cases import build, signature, stability
from prepare_local_spark import RUNTIME, SPARK_VERSION
from run_native_databricks import digest, runtime_path
from run_native_spark import load_runtime


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    output = runtime_path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    fixtures = build()
    own = Path(__file__).parent
    files = ('performance_cases.py', 'run_performance_spark.py', 'run_native_spark.py', 'prepare_local_spark.py')
    hashes = {name: digest(own / name) for name in files}
    report = dict(engine='Apache Spark', generated_at=datetime.now(timezone.utc).isoformat(),
                  source_hashes=hashes, status='not executed', cache_profile='materialized DataFrame cache',
                  cases=[], datasets=[], unsafe_controls=[], databricks_execution='not executed')
    spark = None
    exit_code = 2
    try:
        load_runtime()
        from pyspark.sql import SparkSession
        spark = (SparkSession.builder.master('local[2]').appName('SyntheticSqlDialectPerformance')
            .config('spark.ui.enabled', 'false').config('spark.eventLog.enabled', 'false')
            .config('spark.driver.host', '127.0.0.1').config('spark.driver.bindAddress', '127.0.0.1')
            .config('spark.local.dir', str(RUNTIME / 'performance-work'))
            .config('spark.sql.warehouse.dir', (RUNTIME / 'performance-work/warehouse').as_uri())
            .config('spark.sql.ansi.enabled', 'true').config('spark.sql.session.timeZone', 'UTC')
            .config('spark.sql.timestampType', 'TIMESTAMP_NTZ').config('spark.sql.caseSensitive', 'true')
            .config('spark.sql.shuffle.partitions', '4').config('spark.sql.adaptive.enabled', 'true').getOrCreate())
        spark.sparkContext.setLogLevel('ERROR')
        for name in ('SQLQueryContextLogger', 'DataFrameQueryContextLogger'):
            logging.getLogger(name).disabled = True
        if spark.version != SPARK_VERSION:
            raise RuntimeError('SPARK_VERSION_MISMATCH')
        report.update(spark_version=spark.version, session=dict(ansi=True, timezone='UTC', aqe=True, shuffle_partitions=4))
        exit_code = 0
        for dataset in fixtures['datasets']:
            size = dataset['events']
            event = spark.sql(f'''SELECT EventId,ParentId,EventTick,timestampadd(SECOND,EventTick,CAST('2026-01-01' AS TIMESTAMP_NTZ)) EventTime
              FROM (SELECT CAST(id+1 AS INT) EventId,
              CASE WHEN id%997=0 THEN CAST(NULL AS INT) ELSE CAST(id%1000+1 AS INT) END ParentId,
              CASE WHEN id%97=0 THEN CAST(NULL AS INT) ELSE CAST((id DIV 1000) DIV 2 AS INT) END EventTick
              FROM range(0,{size},1,4))''').cache()
            parent = spark.sql(f'''SELECT CAST(id+1 AS INT) RowId,
              CASE WHEN id%97=0 THEN CAST(NULL AS INT) WHEN id%113=0 THEN 1001 ELSE CAST(id%1000+1 AS INT) END ParentId,
              CASE WHEN id%89=0 THEN CAST(NULL AS TIMESTAMP_NTZ) ELSE timestampadd(SECOND,
              CAST((({size // 1000}*CASE WHEN id<1000 THEN 1 ELSE 3 END) DIV 4) DIV 2 AS INT),CAST('2026-01-01' AS TIMESTAMP_NTZ)) END CutoffTime
              FROM range(0,2000,1,4)''').cache()
            try:
                event.createOrReplaceTempView('PerfEvent'); parent.createOrReplaceTempView('PerfParent')
                if parent.count() != 2000 or event.count() != size:
                    raise RuntimeError('FIXTURE_COUNT_MISMATCH')
                totals = spark.sql('''SELECT COUNT(*) events,SUM(CAST(EventId AS BIGINT)) sum_id,
                  SUM(CAST(COALESCE(ParentId,0) AS BIGINT)) sum_parent,
                  SUM(CASE WHEN ParentId IS NULL THEN 1 ELSE 0 END) null_parent,
                  SUM(CASE WHEN EventTime IS NULL THEN 1 ELSE 0 END) null_time,
                  SUM(CAST(COALESCE(EventTick,0) AS BIGINT)) sum_tick FROM PerfEvent''').collect()[0].asDict()
                if totals != dataset['totals']:
                    raise RuntimeError('FIXTURE_TOTALS_MISMATCH')
                report['datasets'].append(dict(events=size, status='validated'))
                for case in fixtures['spark_cases']:
                    wanted = dataset['expected'][case['scenario']]
                    entry = dict(events=size, layout='cached', name=case['name'], status='failed', batches=[])
                    group = str(size) + '/' + case['name']
                    spark.sparkContext.setJobGroup(group, 'Fixed synthetic performance query', interruptOnCancel=True)

                    def execute():
                        timer = Timer(45, spark.sparkContext.cancelJobGroup, args=(group,))
                        timer.daemon = True; timer.start()
                        try:
                            start = perf_counter()
                            frame = spark.sql(case['sql'])
                            rows = frame.collect()
                            elapsed = (perf_counter() - start) * 1000
                        finally:
                            timer.cancel()
                        # Orakel und Hashsortierung gehören nicht in das Zeitfenster.
                        if len(rows) != wanted['rows'] or signature(rows, case['ordered']) != wanted['sha256']:
                            raise RuntimeError('RESULT_ORACLE_MISMATCH')
                        return elapsed, frame

                    for _ in range(4):
                        execute()
                    frame = None
                    for _ in range(fixtures['batches']):
                        samples = []
                        for _ in range(fixtures['repetitions']):
                            elapsed, frame = execute(); samples.append(elapsed)
                        entry['batches'].append(samples)
                    # Finaler tatsächlich ausgeführter AQE-Plan desselben Resultsets.
                    physical = frame._jdf.queryExecution().executedPlan().toString()
                    optimized = frame._jdf.queryExecution().optimizedPlan().toString()
                    final_physical = physical.split('== Initial Plan ==')[0]
                    plan_name = f"{size}_{case['name'].replace('/', '_')}.sparkplan"
                    (output.parent / plan_name).write_text(physical + '\n\n' + optimized + '\n', encoding='utf-8')
                    entry.update(status='validated', rows=wanted['rows'], result_sha256=wanted['sha256'],
                                 stability=stability(entry['batches']), plan_file=plan_name,
                                 plan_operators=[name for name in ('InMemoryTableScan','WindowGroupLimit','Window','Sort',
                                    'Exchange','BroadcastHashJoin','SortMergeJoin','TakeOrderedAndProject','CartesianProduct') if name in final_physical],
                                 aqe_final='isFinalPlan=true' in physical)
                    report['cases'].append(entry)
                    print(json.dumps(dict(events=size, name=case['name'], status=entry['status'], stability=entry['stability']['status'])), flush=True)
                wrong = spark.sql(fixtures['unsafe_spark']).collect()
                if signature(wrong) == dataset['expected']['cutoff']['sha256']:
                    raise RuntimeError('UNSAFE_REWRITE_CONTROL_FAILED')
                report['unsafe_controls'].append(dict(events=size, status='validated', code='CUTOFF_AFTER_RANK_DETECTED'))
            finally:
                parent.unpersist(blocking=True); event.unpersist(blocking=True)
                spark.catalog.dropTempView('PerfParent'); spark.catalog.dropTempView('PerfEvent')
        report['status'] = 'validated'
    except Exception as error:
        safe = str(error)
        report['code'] = safe if safe in ('SPARK_VERSION_MISMATCH','FIXTURE_COUNT_MISMATCH','FIXTURE_TOTALS_MISMATCH',
            'RESULT_ORACLE_MISMATCH','UNSAFE_REWRITE_CONTROL_FAILED') else 'LOCAL_OR_SPARK_FAILURE'
        report['status'] = 'failed' if spark is not None else 'not executed'
        exit_code = 1 if spark is not None else 2
    finally:
        if spark is not None:
            spark.stop()
    for name, wanted in hashes.items():
        if digest(own / name) != wanted:
            report.update(status='failed', code='SOURCE_DRIFT'); exit_code = 1
    output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(dict(status=report['status'], cases=len(report['cases']), code=report.get('code'))))
    return exit_code


if __name__ == '__main__':
    raise SystemExit(main())
