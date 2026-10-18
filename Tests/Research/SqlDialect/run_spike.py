"""Begrenzter SQLGlot-Spike; synthetische Fixtures, keine SQL-Ausführung.

Der Harness beobachtet die gepinnte Bibliothek und erzeugt nur lokale Berichte.
Er ist kein produktiver Transpiler und nimmt keinen fremden SQL-Text entgegen.
"""

from __future__ import annotations

import argparse
from collections import Counter
import json
import logging
from pathlib import Path
import sys

import sqlglot
from sqlglot import ErrorLevel, exp


PIN = "30.23.0"
ROOT = Path(__file__).resolve().parents[3]


def fixtures() -> list[dict[str, str]]:
    """Die Richtungen sind getrennte Eingaben, keine bloßen Roundtrips."""
    pairs = [
        ("cte-join",
         "WITH a AS (SELECT ParentId FROM Parent WHERE ParentId > 0) SELECT a.ParentId, e.EventId FROM a LEFT JOIN Event e ON e.ParentId = a.ParentId",
         "WITH a AS (SELECT ParentId FROM Parent WHERE ParentId > 0) SELECT a.ParentId, e.EventId FROM a LEFT JOIN Event e ON e.ParentId = a.ParentId"),
        ("outer-simple",
         "SELECT p.ParentId, r.EventId FROM Parent p OUTER APPLY (SELECT e.EventId FROM Event e WHERE e.ParentId = p.ParentId) r",
         "SELECT p.ParentId, r.EventId FROM Parent p LEFT JOIN LATERAL (SELECT e.EventId FROM Event e WHERE e.ParentId = p.ParentId) r ON TRUE"),
        ("cross-simple",
         "SELECT p.ParentId, r.EventId FROM Parent p CROSS APPLY (SELECT e.EventId FROM Event e WHERE e.ParentId = p.ParentId) r",
         "SELECT p.ParentId, r.EventId FROM Parent p CROSS JOIN LATERAL (SELECT e.EventId FROM Event e WHERE e.ParentId = p.ParentId) r"),
        ("outer-top1",
         "SELECT p.ParentId, r.EventId FROM Parent p OUTER APPLY (SELECT TOP (1) e.EventId FROM Event e WHERE e.ParentId = p.ParentId ORDER BY e.EventId DESC) r",
         "SELECT p.ParentId, r.EventId FROM Parent p LEFT JOIN LATERAL (SELECT e.EventId FROM Event e WHERE e.ParentId = p.ParentId ORDER BY e.EventId DESC LIMIT 1) r ON TRUE"),
        ("ordered-top3",
         "SELECT TOP (3) EventId FROM Event ORDER BY EventId DESC",
         "SELECT EventId FROM Event ORDER BY EventId DESC LIMIT 3"),
        ("outer-cutoff",
         "SELECT p.ParentId, r.EventId FROM Parent p OUTER APPLY (SELECT TOP (1) e.EventId FROM Event e WHERE e.ParentId = p.ParentId AND e.EventTime <= p.CutoffTime ORDER BY e.EventTime DESC, e.EventId DESC) r",
         "SELECT p.ParentId, r.EventId FROM Parent p LEFT JOIN LATERAL (SELECT e.EventId FROM Event e WHERE e.ParentId = p.ParentId AND e.EventTime <= p.CutoffTime ORDER BY e.EventTime DESC, e.EventId DESC LIMIT 1) r ON TRUE"),
        ("window-top3",
         "WITH r AS (SELECT ParentId, EventId, ROW_NUMBER() OVER (PARTITION BY ParentId ORDER BY EventId DESC) rn FROM Event) SELECT p.ParentId, r.EventId FROM Parent p LEFT JOIN r ON r.ParentId = p.ParentId AND r.rn <= 3",
         "WITH r AS (SELECT ParentId, EventId, ROW_NUMBER() OVER (PARTITION BY ParentId ORDER BY EventId DESC) rn FROM Event) SELECT p.ParentId, r.EventId FROM Parent p LEFT JOIN r ON r.ParentId = p.ParentId AND r.rn <= 3"),
        ("scalar-count",
         "SELECT p.ParentId, r.cnt FROM Parent p OUTER APPLY (SELECT COUNT_BIG(*) cnt FROM Event e WHERE e.ParentId = p.ParentId) r",
         "SELECT p.ParentId, r.cnt FROM Parent p LEFT JOIN LATERAL (SELECT COUNT(*) cnt FROM Event e WHERE e.ParentId = p.ParentId) r ON TRUE"),
        ("casts",
         "SELECT CAST(1 AS INT) i, CAST(1 AS BIGINT) b, CAST(1.25 AS DECIMAL(12,2)) d, CAST('2026-01-02' AS DATE) dt, CAST('2026-01-02T03:04:05.1234567' AS DATETIME2(7)) tm, CAST('abcdef' AS VARCHAR(3)) s, CAST(N'abcdef' AS NVARCHAR(3)) ns, CAST(255 AS TINYINT) tiny, CAST(1 AS BIT) flag",
         "SELECT CAST(1 AS INT) i, CAST(1 AS BIGINT) b, CAST(1.25 AS DECIMAL(12,2)) d, CAST('2026-01-02' AS DATE) dt, CAST('2026-01-02 03:04:05.123456' AS TIMESTAMP_NTZ) tm, CAST('abcdef' AS STRING) s, CAST(-1 AS TINYINT) tiny, CAST(TRUE AS BOOLEAN) flag"),
        ("aggregate-types",
         "SELECT COUNT(*) c, COUNT_BIG(*) cb, SUM(CAST(Amount AS INT)) s, AVG(CAST(Amount AS INT)) a, ROW_NUMBER() OVER (ORDER BY ParentId) rn FROM Parent GROUP BY ParentId",
         "SELECT COUNT(*) c, SUM(CAST(Amount AS INT)) s, AVG(CAST(Amount AS INT)) a, ROW_NUMBER() OVER (ORDER BY ParentId) rn FROM Parent GROUP BY ParentId"),
        ("date-functions",
         "SELECT DATEADD(day, 2, CAST('2026-01-02' AS DATE)) d, DATEDIFF(day, CAST('2026-01-02' AS DATE), CAST('2026-01-05' AS DATE)) n",
         "SELECT date_add(CAST('2026-01-02' AS DATE), 2) d, datediff(CAST('2026-01-05' AS DATE), CAST('2026-01-02' AS DATE)) n"),
        ("parameters",
         "SELECT p.ParentId FROM dbo.Parent p WHERE p.ParentId = @ParentId",
         "SELECT p.ParentId FROM main.default.Parent p WHERE p.ParentId = :ParentId"),
        ("unknown-function",
         "SELECT ContosoScore(ParentId) score FROM Parent",
         "SELECT ContosoScore(ParentId) score FROM Parent"),
    ]
    cases = []
    for name, tsql, databricks in pairs:
        cases.append(dict(name=name + "/tsql", source="tsql", target="databricks", sql=tsql))
        cases.append(dict(name=name + "/databricks", source="databricks", target="tsql", sql=databricks))
    extras = [
        ("qualify/databricks", "databricks", "tsql", "SELECT ParentId, EventId FROM Event QUALIFY ROW_NUMBER() OVER (PARTITION BY ParentId ORDER BY EventId DESC) <= 3"),
        ("top-ties/tsql", "tsql", "databricks", "SELECT TOP (2) WITH TIES ParentId FROM Parent ORDER BY ParentId"),
        ("top-percent/tsql", "tsql", "databricks", "SELECT TOP (10) PERCENT ParentId FROM Parent ORDER BY ParentId"),
        ("top-unordered/tsql", "tsql", "databricks", "SELECT TOP (1) EventId FROM Event"),
        ("command-fallback/tsql", "tsql", "databricks", "PRINT N'synthetic'"),
        ("nolock/tsql", "tsql", "databricks", "SELECT ParentId FROM Parent WITH (NOLOCK)"),
    ]
    for name, source, target, query in extras:
        cases.append(dict(name=name, source=source, target=target, sql=query))
    return cases


class Capture(logging.Handler):
    """Nur Diagnostik des jeweiligen synthetischen Falls einsammeln."""

    def __init__(self) -> None:
        super().__init__()
        self.messages: list[str] = []

    def emit(self, record: logging.LogRecord) -> None:
        self.messages.append(record.getMessage())


def probe(case: dict[str, str]) -> dict[str, object]:
    """Strikter Generator und erneutes Parsen sind keine Enginevalidierung."""
    result: dict[str, object] = dict(case)
    capture = Capture()
    logger = logging.getLogger("sqlglot")
    previous_propagate = logger.propagate
    logger.propagate = False
    logger.addHandler(capture)
    stage = "source_parse"
    try:
        trees = sqlglot.parse(case["sql"], read=case["source"], error_level=ErrorLevel.RAISE)
        if len(trees) != 1 or trees[0] is None:
            raise AssertionError("Fixture muss genau einen AST liefern")
        tree = trees[0]
        result["source_commands"] = len(list(tree.find_all(exp.Command)))
        result["source_lateral_flags"] = [node.args.get("cross_apply") for node in tree.find_all(exp.Lateral)]
        stage = "generation"
        output = tree.sql(dialect=case["target"], unsupported_level=ErrorLevel.RAISE)
        result["output"] = output
        stage = "target_parse"
        target_trees = sqlglot.parse(output, read=case["target"], error_level=ErrorLevel.RAISE)
        result["target_commands"] = sum(len(list(node.find_all(exp.Command))) for node in target_trees if node)
        result["status"] = "generated_and_reparsed"
        try:
            result["roundtrip"] = target_trees[0].sql(dialect=case["source"], unsupported_level=ErrorLevel.RAISE)
        except sqlglot.errors.SqlglotError as error:
            result["roundtrip_error"] = type(error).__name__ + ": " + str(error)
    except sqlglot.errors.SqlglotError as error:
        result["status"] = "rejected"
        result["failure_stage"] = stage
        result["error"] = type(error).__name__ + ": " + str(error)
    finally:
        result["diagnostics"] = capture.messages
        logger.removeHandler(capture)
        logger.propagate = previous_propagate
    return result


def fixed_reverse_experiment(query: str, cross: bool) -> str:
    """Nur zwei feste Fixtures: AST-Hypothese für die Rückrichtung erproben.

    ON TRUE darf entfernt werden; beliebige ON-Prädikate dürfen es nicht.
    Diese Funktion wird nicht für fremde Eingaben oder als Produkt-API benutzt.
    """
    tree = sqlglot.parse_one(query, read="databricks", error_level=ErrorLevel.RAISE)
    joins = list(tree.find_all(exp.Join))
    assert len(joins) == 1 and isinstance(joins[0].this, exp.Lateral)
    join = joins[0]
    if cross:
        assert join.kind == "CROSS" and join.args.get("on") is None
    else:
        assert join.side == "LEFT" and isinstance(join.args.get("on"), exp.Boolean)
        assert join.args["on"].this is True
    join.this.set("cross_apply", cross)
    join.set("side", None)
    join.set("kind", None)
    join.set("on", None)
    output = tree.sql(dialect="tsql", unsupported_level=ErrorLevel.RAISE)
    reparsed = sqlglot.parse_one(output, read="tsql", error_level=ErrorLevel.RAISE)
    assert next(reparsed.find_all(exp.Lateral)).args["cross_apply"] is cross
    return output


def verify_observations(results: list[dict[str, object]]) -> list[str]:
    """Erwartete Providergrenzen festhalten; kein semantisches Engineorakel.

    Die Assertions sichern auch problematische Beobachtungen. Ihr PASS bedeutet
    nicht, dass die ausgegebenen Statements den Toolbelt-Vertrag erfüllen.
    """
    indexed = {result["name"]: result for result in results}
    checks: list[str] = []

    def require(condition: object, name: str) -> None:
        if not condition:
            raise AssertionError(name)
        checks.append(name)

    require(Counter(result["status"] for result in results) == {
        "generated_and_reparsed": 26, "rejected": 6,
    }, "corpus-outcomes")
    for name in ("outer-simple", "cross-simple", "outer-top1", "outer-cutoff", "scalar-count"):
        reverse = indexed[name + "/databricks"]
        require(reverse["status"] == "rejected" and "LATERAL clause is not supported" in str(reverse["error"]),
                name + "-reverse-rejected")
        forward = indexed[name + "/tsql"]
        require(forward["status"] == "generated_and_reparsed", name + "-forward-generated")
    top = sqlglot.parse_one(str(indexed["outer-top1/tsql"]["output"]), read="databricks")
    require(len(list(top.find_all(exp.Limit))) == 1 and not list(top.find_all(exp.RowNumber)),
            "top1-stays-correlated-not-window-decorrelated")
    require(" ON " not in str(indexed["outer-top1/tsql"]["output"])
            and next(top.find_all(exp.Join)).args["on"].this is True,
            "forward-lateral-omits-on-target-parser-inserts-true")
    for dialect in ("tsql", "databricks"):
        window = sqlglot.parse_one(str(indexed["window-top3/" + dialect]["output"]),
                                  read=indexed["window-top3/" + dialect]["target"])
        require(not list(window.find_all(exp.Lateral)) and next(window.find_all(exp.Join)).args.get("on") is not None,
                "prewritten-window-keeps-join-" + dialect)
        limited = str(indexed["ordered-top3/" + dialect]["output"])
        require(("LIMIT 3" in limited if dialect == "tsql" else "TOP 3" in limited),
                "ordered-global-limit-" + dialect)
    qualify = sqlglot.parse_one(str(indexed["qualify/databricks"]["output"]), read="tsql")
    require(not list(qualify.find_all(exp.Qualify)) and len(list(qualify.find_all(exp.RowNumber))) == 1,
            "qualify-lowered-to-window-subquery")
    aggregate_forward = str(indexed["aggregate-types/tsql"]["output"])
    aggregate_reverse = str(indexed["aggregate-types/databricks"]["output"])
    require("COUNT(*) AS c, COUNT(*) AS cb" in aggregate_forward, "forward-count-width-not-preserved-by-cast")
    require("COUNT_BIG(*) AS c" in aggregate_reverse, "reverse-count-bigint-adaptation-present")
    require("AVG(CAST(Amount AS INT))" in aggregate_forward and "SUM(CAST(Amount AS INT))" in aggregate_forward,
            "forward-sum-avg-no-result-type-compensation")
    casts_forward = str(indexed["casts/tsql"]["output"])
    casts_reverse = str(indexed["casts/databricks"]["output"])
    require("DECIMAL(12, 2)" in casts_forward and "NUMERIC(12, 2)" in casts_reverse,
            "decimal-precision-scale-syntax-retained")
    require("CAST(255 AS SMALLINT)" in casts_forward and "CAST(-1 AS TINYINT)" in casts_reverse,
            "tinyint-forward-widened-reverse-signed-domain-gap")
    require(" AS TIMESTAMP) AS tm" in casts_forward and " AS DATETIME2) AS tm" in casts_reverse,
            "timestamp-precision-and-ntz-profile-not-explicit")
    require("VARCHAR(3)" in casts_forward and "VARCHAR(MAX)" in casts_reverse,
            "text-type-syntax-needs-semantic-contract")
    require("${ParentId}" in str(indexed["parameters/tsql"]["output"])
            and ":ParentId" in str(indexed["parameters/databricks"]["output"]),
            "parameters-not-mapped-to-required-native-markers")
    for name, marker in (("top-ties/tsql", "LIMIT 2 WITH TIES"), ("top-percent/tsql", "LIMIT 10 PERCENT")):
        require(marker in str(indexed[name]["output"]), name + "-target-parser-accepts-foreign-options")
    require("ORDER BY" not in str(indexed["top-unordered/tsql"]["output"]),
            "unordered-top-not-rejected")
    for dialect in ("tsql", "databricks"):
        require("CONTOSOSCORE(" in str(indexed["unknown-function/" + dialect]["output"]),
                "unknown-function-passed-through-" + dialect)
    fallback = indexed["command-fallback/tsql"]
    require(fallback["source_commands"] == 1 and "PRINT N'synthetic'" == fallback["output"]
            and fallback["failure_stage"] == "target_parse" and bool(fallback["diagnostics"]),
            "strict-source-and-generator-allow-command-target-reparse-rejects")
    nolock = indexed["nolock/tsql"]
    require("NOLOCK" not in str(nolock["output"]) and not nolock["diagnostics"], "nolock-dropped-without-diagnostic")
    return checks


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True, help="Bericht ausschließlich unter .runtime/")
    args = parser.parse_args()
    if sqlglot.__version__ != PIN:
        parser.error(f"Erfordert SQLGlot {PIN}, tatsächlich {sqlglot.__version__}")
    output = args.output.resolve()
    if not output.is_relative_to(ROOT / ".runtime"):
        parser.error("Laufzeitbericht muss unter dem ignorierten .runtime/-Verzeichnis liegen")
    cases = fixtures()
    assert len(cases) == 32
    results = [probe(case) for case in cases]
    checks = verify_observations(results)
    by_name = {case["name"]: case for case in cases}
    experiments = {
        "fixed-outer-top1": fixed_reverse_experiment(by_name["outer-top1/databricks"]["sql"], False),
        "fixed-cross-simple": fixed_reverse_experiment(by_name["cross-simple/databricks"]["sql"], True),
    }
    try:
        fixed_reverse_experiment(by_name["outer-top1/databricks"]["sql"].replace("ON TRUE", "ON r.EventId > 0"), False)
    except AssertionError:
        checks.append("fixed-reverse-rejects-additional-on-predicate")
    else:
        raise AssertionError("Zusätzliches ON-Prädikat wurde unzulässig entfernt")
    report = dict(sqlglot_version=PIN, python_version=sys.version.split()[0], cases=results,
                  fixed_ast_experiments=experiments, observation_assertions=checks, engine_execution="not executed",
                  performance_measurement="not executed")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(dict(cases=len(results), outcomes=dict(Counter(str(r["status"]) for r in results)),
                         fixed_ast_experiments=len(experiments), observation_assertions=len(checks), engine_execution="not executed")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
