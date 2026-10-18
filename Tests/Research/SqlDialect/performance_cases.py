"""Feste synthetische Workloads und unabhängige Orakel für den Perf-Spike.

Keine Produktoptimierung und kein CLI für fremden SQL-Text. Zeiten, Rohpläne
und reale Umgebungswerte werden ausschließlich unter .runtime/ gespeichert.
"""

from __future__ import annotations

import argparse
import hashlib
import heapq
import json
from pathlib import Path
import statistics

from run_spike import ROOT

SIZES = (100_000, 1_000_000)
KEYS = 1000
PARENTS = 2000
BATCHES = 3
REPETITIONS = 3
STABILITY_PERCENT = 20.0


def parent_rows(size: int) -> list[tuple]:
    return [(j + 1, None if j % 97 == 0 else 1001 if j % 113 == 0 else j % KEYS + 1,
             None if j % 89 == 0 else ((size // KEYS) * (1 if j < KEYS else 3) // 4) // 2)
            for j in range(PARENTS)]


def keep(heap: list, value: tuple, count: int) -> None:
    if len(heap) < count:
        heapq.heappush(heap, value)
    elif value > heap[0]:
        heapq.heapreplace(heap, value)


def oracle(size: int) -> dict:
    parents = parent_rows(size)
    cutoffs = sorted({p[2] for p in parents if p[2] is not None})
    latest, bounded, global_top = {}, {c: {} for c in cutoffs}, []
    totals = dict(events=size, sum_id=0, sum_parent=0, null_parent=0, null_time=0, sum_tick=0)
    for i in range(size):
        eid = i + 1
        key = None if i % 997 == 0 else i % KEYS + 1
        tick = None if i % 97 == 0 else (i // KEYS) // 2
        totals['sum_id'] += eid
        totals['sum_parent'] += key or 0
        totals['null_parent'] += key is None
        totals['null_time'] += tick is None
        totals['sum_tick'] += tick or 0
        value = (tick if tick is not None else -1, eid, key)
        keep(global_top, value, 100)
        if key is None:
            continue
        keep(latest.setdefault(key, []), value, 3)
        if tick is not None:
            for cutoff in cutoffs:
                if tick <= cutoff:
                    keep(bounded[cutoff].setdefault(key, []), value, 1)
    output = {}
    for scenario, scope, top, cutoff in [('selective', 32, 1, False), ('broad', PARENTS, 3, False), ('cutoff', PARENTS, 1, True)]:
        rows = []
        for rowid, key, bound in parents[:scope]:
            candidates = [] if key is None or (cutoff and bound is None) else (
                bounded[bound].get(key, []) if cutoff else latest.get(key, []))
            chosen = sorted(candidates, reverse=True)[:top]
            rows.extend((rowid, key, e[1], None if e[0] == -1 else e[0]) for e in chosen)
            if not chosen:
                rows.append((rowid, key, None, None))
        output[scenario] = rows
    output['global'] = [(0, e[2], e[1], None if e[0] == -1 else e[0]) for e in sorted(global_top, reverse=True)]
    return dict(rows=output, totals=totals)


def signature(rows: list, ordered: bool = False) -> str:
    lines = [','.join('N' if v is None else str(v) for v in row) for row in rows]
    if not ordered:
        lines.sort()
    return hashlib.sha256(('\n'.join(lines) + '\n').encode()).hexdigest()


def query(dialect: str, scenario: str, variant: str) -> str:
    event, parent = ('#PerfEvent', '#PerfParent') if dialect == 'tsql' else ('PerfEvent', 'PerfParent')
    scope = 32 if scenario == 'selective' else PARENTS
    top = 3 if scenario == 'broad' else 100 if scenario == 'global' else 1
    order = 'e.EventTime DESC,e.EventId DESC'
    projection = 'p.RowId,p.ParentId,r.EventId,r.EventTick'
    cutoff = ' AND e.EventTime<=p.CutoffTime' if scenario == 'cutoff' else ''
    suffix = f' WHERE p.RowId<={scope}'
    if scenario == 'global':
        if variant == 'correlated':
            head = f'SELECT TOP ({top})' if dialect == 'tsql' else 'SELECT'
            return f'{head} CAST(0 AS INT) RowId,e.ParentId,e.EventId,e.EventTick FROM {event} e ORDER BY {order}' + (f' LIMIT {top}' if dialect == 'spark' else '')
        return f'WITH Ranked AS (SELECT e.ParentId,e.EventId,e.EventTick,e.EventTime,ROW_NUMBER() OVER(ORDER BY {order}) rn FROM {event} e) SELECT CAST(0 AS INT) RowId,r.ParentId,r.EventId,r.EventTick FROM Ranked r WHERE r.rn<={top} ORDER BY r.EventTime DESC,r.EventId DESC'
    if variant == 'correlated':
        inner = (f'SELECT TOP ({top})' if dialect == 'tsql' else 'SELECT') + f' e.EventId,e.EventTick FROM {event} e WHERE e.ParentId=p.ParentId{cutoff} ORDER BY {order}'
        if dialect == 'spark':
            inner += f' LIMIT {top}'
        join = f'OUTER APPLY ({inner}) r' if dialect == 'tsql' else f'LEFT JOIN LATERAL ({inner}) r ON TRUE'
        return f'SELECT {projection} FROM {parent} p {join}{suffix}'
    if scenario == 'cutoff' and variant == 'window_eligible':
        return f'WITH Ranked AS (SELECT p.RowId,e.EventId,e.EventTick,ROW_NUMBER() OVER(PARTITION BY p.RowId ORDER BY {order}) rn FROM {parent} p JOIN {event} e ON e.ParentId=p.ParentId{cutoff}{suffix}) SELECT {projection} FROM {parent} p LEFT JOIN Ranked r ON r.RowId=p.RowId AND r.rn<={top}{suffix}'
    filtered = f' WHERE e.ParentId IN (SELECT p.ParentId FROM {parent} p WHERE p.RowId<={scope})' if variant == 'window_filtered' else ''
    later = ' AND r.EventTime<=p.CutoffTime' if variant == 'unsafe_cutoff_after_rank' else ''
    return f'WITH Ranked AS (SELECT e.ParentId,e.EventId,e.EventTick,e.EventTime,ROW_NUMBER() OVER(PARTITION BY e.ParentId ORDER BY {order}) rn FROM {event} e{filtered}) SELECT {projection} FROM {parent} p LEFT JOIN Ranked r ON r.ParentId=p.ParentId AND r.rn<={top}{later}{suffix}'


def cases(dialect: str) -> list[dict]:
    output = []
    for scenario in ('selective', 'broad', 'cutoff', 'global'):
        variants = ('correlated', 'window_global', 'window_filtered') if scenario in ('selective', 'broad') else ('correlated', 'window_eligible') if scenario == 'cutoff' else ('correlated', 'window_global')
        for variant in variants:
            output.append(dict(name=f'{scenario}/{variant}', scenario=scenario, variant=variant,
                               sql=query(dialect, scenario, variant), ordered=scenario == 'global'))
    assert len(output) == 10
    return output


def stability(batches: list[list[float]]) -> dict:
    if len(batches) != BATCHES or any(len(batch) != REPETITIONS for batch in batches):
        return dict(status='not executed', code='INCOMPLETE_REPETITIONS')
    medians = [statistics.median(batch) for batch in batches]
    drift = (max(medians) / min(medians) - 1) * 100 if min(medians) > 0 else float('inf')
    confirmation = abs(medians[2] / statistics.median(medians[:2]) - 1) * 100 if min(medians) > 0 else float('inf')
    qualified = drift <= STABILITY_PERCENT and confirmation <= STABILITY_PERCENT
    return dict(status='validated' if qualified else 'not executed', code=None if qualified else 'PERFORMANCE_STABILITY_UNAVAILABLE',
                batch_medians_ms=medians, median_ms=statistics.median(medians), drift_percent=drift,
                confirmation_percent=confirmation, threshold_percent=STABILITY_PERCENT)


def build() -> dict:
    datasets = []
    for size in SIZES:
        expected = oracle(size)
        datasets.append(dict(events=size, parents=PARENTS, keys=KEYS, totals=expected['totals'],
            expected={name: dict(rows=len(rows), sha256=signature(rows, name == 'global')) for name, rows in expected['rows'].items()}))
    return dict(datasets=datasets, tsql_cases=cases('tsql'), spark_cases=cases('spark'),
                unsafe_tsql=query('tsql', 'cutoff', 'unsafe_cutoff_after_rank'),
                unsafe_spark=query('spark', 'cutoff', 'unsafe_cutoff_after_rank'),
                batches=BATCHES, repetitions=REPETITIONS, stability_percent=STABILITY_PERCENT)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    if not output.is_relative_to(ROOT / '.runtime'):
        parser.error('Ausgabe ausschließlich unter .runtime/')
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(build(), indent=2) + '\n', encoding='utf-8')
    print('Generated two fixed datasets, 10 query variants per engine, independent oracles')
