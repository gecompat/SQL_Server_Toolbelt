"""Erzeugt feste native T-SQL-Prüffälle aus dem aktuellen Researchkern.

Keine Verbindung, kein fremder SQL-Input. CTE-/VALUES-Fixtures vermeiden
persistente Objekte und Änderungen an gemeinsam benutzten Labdatenbanken.
Erwartungswerte entstehen unabhängig vom SQL-Generator als Python-Relationen.
"""

from __future__ import annotations

import argparse
from dataclasses import replace
import hashlib
import json
from pathlib import Path

import sqlglot

from rules_probe import rewrite
from run_rule_spike import cases, result_cast_cases
from run_spike import PIN, ROOT


PARENTS = [(1, "2026-01-02T12:00:00"), (1, "2026-01-04T12:00:00"),
           (2, "2026-01-03T12:00:00"), (3, None),
           (None, "2026-01-03T12:00:00"), (4, "2026-01-01T12:00:00")]
EVENTS = [(101, 1, "2026-01-01T10:00:00"), (102, 1, "2026-01-03T10:00:00"),
          (103, 1, "2026-01-03T10:00:00"), (201, 3, None),
          (202, 3, "2026-01-02T10:00:00"), (301, None, "2026-01-01T10:00:00"),
          (401, 4, "2026-01-02T10:00:00")]
MARKER = "@ParentId :ParentId TOP (1) PERCENT"


def cte(name: str, names: list[str], types: list[str], rows: list[tuple]) -> str:
    def literal(value: object) -> str:
        if value is None:
            return "NULL"
        if isinstance(value, int):
            return str(value)
        return "'" + str(value).replace("'", "''") + "'"

    if not rows:
        projection = ",".join(f"CAST(NULL AS {dtype}) AS {column}" for column, dtype in zip(names, types))
        return f"{name} AS (SELECT {projection} WHERE 1=0)"
    values = ",".join("(" + ",".join(map(literal, row)) + ")" for row in rows)
    projection = ",".join(f"CAST(v.{column} AS {dtype}) AS {column}" for column, dtype in zip(names, types))
    return f"{name} AS (SELECT {projection} FROM (VALUES {values}) v({','.join(names)}))"


def relations(profile: str) -> tuple[list[tuple], list[tuple]]:
    if profile == "empty":
        return [], []
    if profile == "no-events":
        return PARENTS, []
    if profile == "unique":
        return [(1, None), (2, None), (3, None)], EVENTS
    if profile == "nullable-order":
        return [(None, None), (1, None), (2, None)], EVENTS
    if profile != "main":
        raise AssertionError("Unbekanntes festes Fixtureprofil")
    return PARENTS, EVENTS


def expected(name: str, source: str, profile: str, bindings: dict) -> tuple[list, list]:
    parents, events = relations(profile)
    # Spaltenvertrag ist handgeschrieben; er wird nicht aus dem Ziel-AST abgeleitet.
    columns = {
        "outer": [("ParentId", "int"), ("EventId", "int")],
        "cross": [("ParentId", "int"), ("EventId", "int")],
        "outer-top-parameter": [("ParentId", "int"), ("EventId", "int")],
        "cutoff-preserved": [("ParentId", "int"), ("EventId", "int")],
        "ordered-top": [("EventId", "int")],
        "parameter-lexemes": [("marker", "varchar"), ("ParentId", "int")],
        "exact-types": [("i", "int"), ("b", "bigint"), ("d", "decimal"), ("n", "int")],
        "tinyint-edges": [("a", "smallint"), ("b", "smallint")],
        "date": [("d", "date")], "ntz-six": [("t", "datetime2")],
        "ntz-three": [("t", "datetime2")], "count-width": [("cnt", "bigint")],
        "count-big-kept": [("cnt", "bigint")], "ranking-width": [("rn", "int")],
        "count-null-column": [("cnt", "bigint")],
        "count-parameter-copy": [("cnt", "bigint")], "cast-parameter": [("v", "int")],
    }[name]
    if source == "original":
        columns = [(n, "tinyint" if name == "tinyint-edges" else t) for n, t in columns]
    if source in ("original", "roundtrip"):
        if name in ("count-width", "count-parameter-copy", "count-null-column"):
            columns = [("cnt", "int")]
        elif name == "ranking-width":
            columns = [("rn", "bigint")]
    if name in ("outer", "cross", "outer-top-parameter", "cutoff-preserved"):
        result = []
        for parent, cutoff in parents:
            matches = [e for e in events if parent is not None and e[1] is not None and e[1] == parent]
            if name == "outer-top-parameter":
                floor = bindings["Floor"]
                matches = sorted([e for e in matches if floor is not None and e[0] > floor], reverse=True)[:1]
            elif name == "cutoff-preserved":
                matches = sorted([e for e in matches if cutoff is not None and e[2] is not None and e[2] <= cutoff],
                                 key=lambda e: (e[2], e[0]), reverse=True)[:1]
            result.extend((parent, e[0]) for e in matches)
            if not matches and name != "cross":
                result.append((parent, None))
    elif name == "ordered-top":
        result = [(e[0],) for e in sorted(events, reverse=True)[:3]]
    elif name == "parameter-lexemes":
        result = [(MARKER, p[0]) for p in parents if bindings["ParentId"] is not None and p[0] == bindings["ParentId"]]
    elif name == "exact-types":
        result = [("7", "9", "1.25", None)]
    elif name == "tinyint-edges":
        result = [(0, 255)] if source in ("original", "roundtrip") else [(-128, 127)]
    elif name == "date":
        result = [("2026-01-02",)]
    elif name in ("ntz-six", "ntz-three"):
        result = [("2026-01-02T03:04:05.1234560" if name == "ntz-six" else "2026-01-02T03:04:05.1230000",)]
    elif name in ("count-width", "count-big-kept", "count-parameter-copy"):
        result = [(0 if name == "count-parameter-copy" and bindings["Value"] is None else len(events),)]
    elif name == "count-null-column":
        result = [(sum(event[1] is not None for event in events),)]
    elif name == "ranking-width":
        result = [(i + 1,) for i in range(len(parents))]
    elif name == "cast-parameter":
        result = [(bindings["Value"],)]
    else:
        raise AssertionError("Fehlendes Ergebnisorakel")
    clr = {"int": "System.Int32", "smallint": "System.Int16", "tinyint": "System.Byte",
           "bigint": "System.Int64", "decimal": "System.Decimal", "date": "System.DateTime",
           "datetime2": "System.DateTime", "varchar": "System.String"}
    contracts = []
    for column, dtype in columns:
        contract = dict(name=column, sql_type=dtype, clr_type=clr[dtype])
        if dtype == "decimal":
            contract.update(precision=12, scale=2)
        if dtype == "datetime2":
            contract.update(scale=3 if name == "ntz-three" and source == "original" else 6)
        if dtype == "varchar":
            contract.update(size=len(MARKER))
        contracts.append(contract)
    return [[None if v is None else str(v) for v in row] for row in result], contracts


def build() -> dict:
    if sqlglot.__version__ != PIN:
        raise AssertionError("SQLGlot-Pin stimmt nicht")
    fixtures = cases() + [case for case in result_cast_cases() if case.name.startswith("count-null-column/")]
    positives = {case.name: case for case in fixtures if case.rejection is None}
    output, roundtrip_rejections = [], []

    def add(case, query: str, direction: str, suffix: str = "main", profile: str = "main", bindings: dict | None = None):
        name = case.name.split("/")[0]
        bindings = bindings if bindings is not None else {key: 102 if key == "Floor" else 1 if key == "ParentId" else 7
                                                       for key in case.context.parameters}
        if name == "ranking-width" and profile == "main":
            profile = "unique"  # Zusicherung eindeutiger ParentId tatsächlich einhalten.
        parents, events = relations(profile)
        used = {node.name for node in sqlglot.parse_one(query, read="tsql").find_all(sqlglot.exp.Table)}
        definitions = []
        if "Parent" in used:
            definitions.append(cte("Parent", ["ParentId", "CutoffTime"], ["int", "datetime2(6)"], parents))
        if "Event" in used:
            definitions.append(cte("Event", ["EventId", "ParentId", "EventTime"], ["int", "int", "datetime2(6)"], events))
        # SQL Server lehnt eine vollständig unbenutzte CTE-Hülle mit Fehler 422 ab.
        prefix = ";WITH " + ",".join(definitions) + "\n" if definitions else ""
        rows, columns = expected(name, direction, profile, bindings)
        output.append(dict(name=f"{name}/{direction}/{suffix}", sql=prefix + query,
                           parameters=[dict(name=n, type="Int", value=v) for n, v in bindings.items()],
                           expected_rows=rows, columns=columns, ordered=name == "ordered-top",
                           direction=direction, profile=profile))

    for case in positives.values():
        if case.source != "databricks":
            continue
        rewritten = rewrite(case.query, case.source, case.context)
        assert rewritten["status"] == "rewritten_in_spike"
        add(case, rewritten["sql"], "reverse")
        name = case.name.split("/")[0]
        if name in ("outer", "cross", "outer-top-parameter", "ordered-top", "cutoff-preserved"):
            add(case, rewritten["sql"], "reverse", "no-events", "no-events")
        if name in ("outer", "cross", "count-width", "count-parameter-copy", "count-null-column", "ranking-width"):
            add(case, rewritten["sql"], "reverse", "empty", "empty")
        if case.context.parameters:
            nulls = {key: None for key in case.context.parameters}
            add(case, rewritten["sql"], "reverse", "null-parameter", bindings=nulls)
        if name == "outer-top-parameter":
            add(case, rewritten["sql"], "reverse", "high-floor", bindings={"Floor": 999})
        if name == "cast-parameter":
            for value in (-2147483648, 2147483647):
                add(case, rewritten["sql"], "reverse", "min" if value < 0 else "max", bindings={"Value": value})

    for case in positives.values():
        if case.source != "tsql":
            continue
        forward = rewrite(case.query, "tsql", case.context)
        context = replace(case.context, parameters={p["name"]: p["target_type"] for p in forward["parameters"]})
        back = rewrite(forward["sql"], "databricks", context)
        if back["status"] != "rewritten_in_spike":
            roundtrip_rejections.append(dict(name=case.name, code=back["code"]))
            continue
        add(case, case.query, "original")
        add(case, back["sql"], "roundtrip")
        name = case.name.split("/")[0]
        if name in ("count-width", "count-parameter-copy", "count-null-column", "ranking-width"):
            for direction, query in (("original", case.query), ("roundtrip", back["sql"])):
                add(case, query, direction, "empty", "empty")
                if name == "count-parameter-copy":
                    add(case, query, direction, "null-parameter", bindings={"Value": None})
                    add(case, query, direction, "empty-null-parameter", "empty", {"Value": None})
                if name == "ranking-width":
                    add(case, query, direction, "nullable-order", "nullable-order")

    names = [item["name"] for item in output]
    assert len(names) == len(set(names))
    assert len(output) == 81 and not roundtrip_rejections
    # Unabhängige Anker schützen insbesondere Multiplizität und NULL-Korrelation.
    lookup = {item["name"]: item for item in output}
    assert len(lookup["outer/reverse/main"]["expected_rows"]) == 11
    assert len(lookup["cross/reverse/main"]["expected_rows"]) == 9
    assert lookup["ordered-top/reverse/main"]["expected_rows"] == [["401"], ["301"], ["202"]]
    assert lookup["cutoff-preserved/reverse/main"]["expected_rows"] == [
        ["1", "101"], ["1", "103"], ["2", None], ["3", None], [None, None], ["4", None]]
    for item in output:
        if item["direction"] == "roundtrip":
            original = lookup[item["name"].replace("/roundtrip/", "/original/")]
            assert original["expected_rows"] == item["expected_rows"]
        # Dies bleibt ausdrücklich eine Parserprüfung, kein nativer Binderbeleg.
        parsed = [node for node in sqlglot.parse(item["sql"], read="tsql", error_level=sqlglot.ErrorLevel.RAISE) if node is not None]
        assert len(parsed) == 1 and isinstance(parsed[0], sqlglot.exp.Select)
    files = ("build_native_cases.py", "run_native_lab.ps1", "rules_probe.py", "run_rule_spike.py", "run_spike.py", "requirements.txt")
    hashes = {name: hashlib.sha256((Path(__file__).parent / name).read_bytes()).hexdigest() for name in files}
    return dict(sqlglot_version=PIN, source_hashes=hashes, cases=output, roundtrip_rejections=roundtrip_rejections,
                databricks_execution="not executed", performance="not executed")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    if not output.is_relative_to(ROOT / ".runtime"):
        parser.error("Bericht ausschließlich unter .runtime/")
    payload = build()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(dict(native_cases=len(payload["cases"]), roundtrip_rejections=payload["roundtrip_rejections"])))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
