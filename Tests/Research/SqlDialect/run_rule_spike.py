"""Eigene Researchregeln mit festen positiven und negativen SQL-Fällen prüfen.

Keine Engineausführung und kein CLI für fremden SQL-Text. Der ursprüngliche
Providerharness bleibt unverändert als unabhängige Baseline erhalten.
"""

from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import dataclass, field, replace
import hashlib
import json
from pathlib import Path
import sys

import sqlglot
from sqlglot import ErrorLevel, exp

from rules_probe import ProbeContext, rewrite
from run_spike import PIN, ROOT


@dataclass(frozen=True)
class Case:
    name: str
    source: str
    query: str
    context: ProbeContext = field(default_factory=ProbeContext)
    rejection: str | None = None
    expected: dict[str, object] = field(default_factory=dict)


def cases() -> list[Case]:
    result: list[Case] = []

    def pair(name: str, tsql: str, databricks: str, context: ProbeContext | None = None,
             rejection: str | None = None, expected: dict[str, object] | None = None) -> None:
        for source, query in (("tsql", tsql), ("databricks", databricks)):
            result.append(Case(name + "/" + source, source, query, context or ProbeContext(), rejection, expected or {}))

    pair("outer", "SELECT p.ParentId,r.EventId FROM Parent p OUTER APPLY (SELECT e.EventId FROM Event e WHERE e.ParentId=p.ParentId) r",
         "SELECT p.ParentId,r.EventId FROM Parent p LEFT JOIN LATERAL (SELECT e.EventId FROM Event e WHERE e.ParentId=p.ParentId) r /* ON FALSE ist nur Kommentar */ ON TRUE",
         expected={"join": "outer"})
    pair("cross", "SELECT p.ParentId,r.EventId FROM Parent p CROSS APPLY (SELECT e.EventId FROM Event e WHERE e.ParentId=p.ParentId) r",
         "SELECT p.ParentId,r.EventId FROM Parent p CROSS JOIN LATERAL (SELECT e.EventId FROM Event e WHERE e.ParentId=p.ParentId) r",
         expected={"join": "cross"})
    pair("outer-top-parameter", "SELECT p.ParentId,r.EventId FROM Parent p OUTER APPLY (SELECT TOP(1) e.EventId FROM Event e WHERE e.ParentId=p.ParentId AND e.EventId>@Floor ORDER BY e.EventId DESC) r",
         "SELECT p.ParentId,r.EventId FROM Parent p LEFT JOIN LATERAL (SELECT e.EventId FROM Event e WHERE e.ParentId=p.ParentId AND e.EventId>:Floor ORDER BY e.EventId DESC LIMIT 1) r ON TRUE",
         ProbeContext(parameters={"Floor": "INT"}, unique_orders=frozenset({("e.EventId",)})),
         expected={"join": "outer", "limits": [1], "parameter_uses": {"Floor": 1}})
    pair("ordered-top", "SELECT TOP(3) EventId FROM Event ORDER BY EventId DESC",
         "SELECT EventId FROM Event ORDER BY EventId DESC LIMIT 3",
         ProbeContext(unique_orders=frozenset({("EventId",)})), expected={"limits": [3]})
    pair("parameter-lexemes", "SELECT '@ParentId :ParentId TOP (1) PERCENT' marker,p.ParentId FROM Parent p WHERE p.ParentId=@ParentId OR p.ParentId=@ParentId -- @Ignored",
         "SELECT '@ParentId :ParentId TOP (1) PERCENT' marker,p.ParentId FROM Parent p WHERE p.ParentId=:ParentId OR p.ParentId=:ParentId -- :Ignored",
         ProbeContext(parameters={"ParentId": "INT"}),
         expected={"parameter_uses": {"ParentId": 2}, "text": "@ParentId :ParentId TOP (1) PERCENT"})
    pair("exact-types", "SELECT CAST(7 AS INT) i,CAST(9 AS BIGINT) b,CAST(1.25 AS DECIMAL(12,2)) d,CAST(NULL AS INT) n",
         "SELECT CAST(7 AS INT) i,CAST(9 AS BIGINT) b,CAST(1.25 AS DECIMAL(12,2)) d,CAST(NULL AS INT) n",
         expected={"cast_kinds": ["INT", "BIGINT", "DECIMAL", "INT"], "decimal": [12, 2]})
    pair("tinyint-edges", "SELECT CAST(0 AS TINYINT) a,CAST(255 AS TINYINT) b",
         "SELECT CAST(-128 AS TINYINT) a,CAST(127 AS TINYINT) b", expected={"cast_kinds": ["SMALLINT", "SMALLINT"]})
    pair("date", "SELECT CAST('2026-01-02' AS DATE) d", "SELECT CAST('2026-01-02' AS DATE) d", expected={"cast_kinds": ["DATE"]})
    pair("ntz-six", "SELECT CAST('2026-01-02T03:04:05.123456' AS DATETIME2(6)) t",
         "SELECT CAST('2026-01-02 03:04:05.123456' AS TIMESTAMP_NTZ) t", ProbeContext(ntz6_profile=True), expected={"ntz": True})
    pair("count-width", "SELECT COUNT(*) cnt FROM Event", "SELECT COUNT(*) cnt FROM Event",
         ProbeContext(max_group_rows=1000), expected={"count_width": True})
    pair("ranking-width", "SELECT ROW_NUMBER() OVER(ORDER BY ParentId) rn FROM Parent",
         "SELECT ROW_NUMBER() OVER(ORDER BY ParentId) rn FROM Parent",
         ProbeContext(unique_orders=frozenset({("ParentId",)}), max_partition_rows=1000), expected={"ranking_width": True})
    pair("count-parameter-copy", "SELECT COUNT(@Value) cnt FROM Event", "SELECT COUNT(:Value) cnt FROM Event",
         ProbeContext(parameters={"Value": "INT"}, max_group_rows=1000), expected={"count_width": True, "parameter_uses": {"Value": 1}})
    pair("cast-parameter", "SELECT CAST(@Value AS INT) v", "SELECT CAST(:Value AS INT) v",
         ProbeContext(parameters={"Value": "INT"}), expected={"cast_kinds": ["INT"], "parameter_uses": {"Value": 1}})
    pair("cutoff-preserved", "SELECT p.ParentId,r.EventId FROM Parent p OUTER APPLY(SELECT TOP(1) e.EventId FROM Event e WHERE e.ParentId=p.ParentId AND e.EventTime<=p.CutoffTime ORDER BY e.EventTime DESC,e.EventId DESC) r",
         "SELECT p.ParentId,r.EventId FROM Parent p LEFT JOIN LATERAL(SELECT e.EventId FROM Event e WHERE e.ParentId=p.ParentId AND e.EventTime<=p.CutoffTime ORDER BY e.EventTime DESC,e.EventId DESC LIMIT 1) r ON TRUE",
         ProbeContext(unique_orders=frozenset({("e.EventTime", "e.EventId")})), expected={"join": "outer", "limits": [1], "cutoff": True})

    ordered = ProbeContext(unique_orders=frozenset({("EventId",)}))
    pair("ties", "SELECT TOP(2) WITH TIES EventId FROM Event ORDER BY EventId", "SELECT EventId FROM Event ORDER BY EventId LIMIT 2 WITH TIES", ordered, "limit_options")
    pair("percent", "SELECT TOP(10) PERCENT EventId FROM Event ORDER BY EventId", "SELECT EventId FROM Event ORDER BY EventId LIMIT 10 PERCENT", ordered, "limit_options")
    pair("unordered-limit", "SELECT TOP(1) EventId FROM Event", "SELECT EventId FROM Event LIMIT 1", rejection="order_required")
    pair("uncertified-order", "SELECT TOP(1) EventId FROM Event ORDER BY EventId", "SELECT EventId FROM Event ORDER BY EventId LIMIT 1", rejection="unique_order")
    pair("dynamic-limit", "SELECT TOP(@n) EventId FROM Event ORDER BY EventId", "SELECT EventId FROM Event ORDER BY EventId LIMIT :n", ordered, "limit_literal")
    pair("fractional-limit", "SELECT TOP(1.5) EventId FROM Event ORDER BY EventId", "SELECT EventId FROM Event ORDER BY EventId LIMIT 1.5", ordered, "limit_literal")
    pair("zero-limit", "SELECT TOP(0) EventId FROM Event ORDER BY EventId", "SELECT EventId FROM Event ORDER BY EventId LIMIT 0", ordered, "limit_range")
    pair("large-limit", "SELECT TOP(1001) EventId FROM Event ORDER BY EventId", "SELECT EventId FROM Event ORDER BY EventId LIMIT 1001", ordered, "limit_range")
    pair("tinyint-invalid-source", "SELECT CAST(256 AS TINYINT) v", "SELECT CAST(-129 AS TINYINT) v", rejection="integer_domain")
    pair("integer-invalid-source", "SELECT CAST(2147483648 AS INT) v", "SELECT CAST(2147483648 AS INT) v", rejection="integer_domain")
    pair("decimal-rounding", "SELECT CAST(1.255 AS DECIMAL(12,2)) v", "SELECT CAST(1.255 AS DECIMAL(12,2)) v", rejection="decimal_domain")
    pair("decimal-overflow", "SELECT CAST(1000 AS DECIMAL(3,0)) v", "SELECT CAST(1000 AS DECIMAL(3,0)) v", rejection="decimal_domain")
    pair("high-time-precision", "SELECT CAST('2026-01-02T03:04:05.1234567' AS DATETIME2(7)) v", "SELECT CAST('2026-01-02 03:04:05.123456789' AS TIMESTAMP_NTZ(9)) v", ProbeContext(ntz6_profile=True), "timestamp_precision")
    pair("missing-time-profile", "SELECT CAST('2026-01-02T03:04:05' AS DATETIME2(6)) v", "SELECT CAST('2026-01-02 03:04:05' AS TIMESTAMP_NTZ) v", rejection="timestamp_context")
    pair("offset-time", "SELECT CAST('2026-01-02T03:04:05+01:00' AS DATETIME2(6)) v", "SELECT CAST('2026-01-02 03:04:05+01:00' AS TIMESTAMP_NTZ) v", ProbeContext(ntz6_profile=True), "timestamp_domain")
    pair("text-cast", "SELECT CAST('abcdef' AS NVARCHAR(3)) v", "SELECT CAST('abcdef' AS STRING) v", rejection="unsupported_type")
    pair("bit-cast", "SELECT CAST(1 AS BIT) v", "SELECT CAST(TRUE AS BOOLEAN) v", rejection="unsupported_type")
    pair("missing-parameter-type", "SELECT @p v", "SELECT :p v", rejection="parameter_type")
    pair("parameter-case-collision", "SELECT @p a,@P b", "SELECT :p a,:P b", ProbeContext(parameters={"p": "INT", "P": "INT"}), "parameter_collision")
    pair("unsupported-parameter-type", "SELECT @p v", "SELECT :p v", ProbeContext(parameters={"p": "VARCHAR(10)"}), "unsupported_type")
    pair("sum", "SELECT SUM(Amount) v FROM Event", "SELECT SUM(Amount) v FROM Event", rejection="unsupported_node")
    pair("avg", "SELECT AVG(Amount) v FROM Event", "SELECT AVG(Amount) v FROM Event", rejection="unsupported_node")
    result.append(Case("unknown-function/tsql", "tsql", "SELECT ContosoScore(Amount) v FROM Event", rejection="unsupported_node"))
    result.append(Case("orphan-ranking/databricks", "databricks", "SELECT ROW_NUMBER() rn FROM Parent", rejection="window_shape"))
    pair("hints", "SELECT EventId FROM Event WITH(NOLOCK)", "SELECT /*+ BROADCAST(e) */ e.EventId FROM Event e", rejection="unsupported_node")
    pair("multiple-statements", "SELECT 1 a;SELECT 2 b", "SELECT 1 a;SELECT 2 b", rejection="statement_count")
    pair("invalid-date", "SELECT CAST('2026-02-30' AS DATE) d", "SELECT CAST('2026-02-30' AS DATE) d", rejection="date_domain")
    pair("two-laterals", "SELECT p.ParentId FROM Parent p OUTER APPLY(SELECT e.EventId FROM Event e WHERE e.ParentId=p.ParentId) r OUTER APPLY(SELECT e.EventId FROM Event e WHERE e.ParentId=p.ParentId) s",
         "SELECT p.ParentId FROM Parent p LEFT JOIN LATERAL(SELECT e.EventId FROM Event e WHERE e.ParentId=p.ParentId) r ON TRUE LEFT JOIN LATERAL(SELECT e.EventId FROM Event e WHERE e.ParentId=p.ParentId) s ON TRUE", rejection="lateral_depth")
    pair("offset", "SELECT EventId FROM Event ORDER BY EventId OFFSET 1 ROWS FETCH NEXT 2 ROWS ONLY",
         "SELECT EventId FROM Event ORDER BY EventId LIMIT 2 OFFSET 1", ordered, "select_option")

    result.extend([
        Case("lateral-on-filter/databricks", "databricks", "SELECT p.ParentId,r.EventId FROM Parent p LEFT JOIN LATERAL(SELECT e.EventId FROM Event e WHERE e.ParentId=p.ParentId) r ON r.EventId>0", rejection="lateral_join"),
        Case("lateral-right/databricks", "databricks", "SELECT p.ParentId,r.EventId FROM Parent p RIGHT JOIN LATERAL(SELECT e.EventId FROM Event e WHERE e.ParentId=p.ParentId) r ON TRUE", rejection="lateral_join"),
        Case("non-native-lateral/tsql", "tsql", "SELECT p.ParentId,r.EventId FROM Parent p LEFT JOIN LATERAL(SELECT e.EventId FROM Event e WHERE e.ParentId=p.ParentId) r ON TRUE", rejection="lateral_join"),
        Case("system-parameter/tsql", "tsql", "SELECT @@SPID s", rejection="parameter_marker"),
        Case("positional-parameter/databricks", "databricks", "SELECT ? p", rejection="parameter_marker"),
        Case("legacy-parameter/databricks", "databricks", "SELECT ${p} p", rejection="parameter_marker"),
        Case("count-missing-bound/tsql", "tsql", "SELECT COUNT(*) cnt FROM Event", rejection="count_bound"),
        Case("count-large-bound/tsql", "tsql", "SELECT COUNT(*) cnt FROM Event", ProbeContext(max_group_rows=2**31), "count_bound"),
        Case("count-big-kept/tsql", "tsql", "SELECT COUNT_BIG(*) cnt FROM Event", expected={"count_big": True}),
        Case("timestamp-rounding/tsql", "tsql", "SELECT CAST('2026-01-02T03:04:05.123456' AS DATETIME2(3)) v", ProbeContext(ntz6_profile=True), "timestamp_domain"),
        Case("unknown-column-cast/tsql", "tsql", "SELECT CAST(Amount AS INT) v FROM Event", rejection="cast_domain"),
        Case("rank-missing-bound/databricks", "databricks", "SELECT ROW_NUMBER() OVER(ORDER BY ParentId) rn FROM Parent", ProbeContext(unique_orders=frozenset({("ParentId",)})), "partition_bound"),
        Case("print-command/tsql", "tsql", "PRINT N'synthetic'", rejection="query_shape"),
        Case("lateral-no-condition/databricks", "databricks", "SELECT p.ParentId,r.EventId FROM Parent p LEFT JOIN LATERAL(SELECT e.EventId FROM Event e WHERE e.ParentId=p.ParentId) r", rejection="lateral_condition"),
        Case("rank-large-bound/tsql", "tsql", "SELECT ROW_NUMBER() OVER(ORDER BY ParentId) rn FROM Parent", ProbeContext(unique_orders=frozenset({("ParentId",)}), max_partition_rows=2**31), "partition_bound"),
        Case("ntz-three/tsql", "tsql", "SELECT CAST('2026-01-02T03:04:05.123' AS DATETIME2(3)) t", ProbeContext(ntz6_profile=True), expected={"ntz": True}),
    ])
    if len(result) > 100:
        raise AssertionError("Researchwelle auf höchstens 100 feste Regelfälle begrenzt")
    return result


def result_cast_cases() -> list[Case]:
    """Eigene Folgewelle; die ursprünglichen 100 Eingaben bleiben erhalten."""
    result = []
    count_context = ProbeContext(max_group_rows=1000)
    rank_context = ProbeContext(unique_orders=frozenset({("ParentId",)}), max_partition_rows=1000)

    def pair(name, tsql, databricks, context, rejection=None, expected=None):
        for source, query in (("tsql", tsql), ("databricks", databricks)):
            result.append(Case(name + "/" + source, source, query, context, rejection, expected or {}))

    for dtype in ("INT", "BIGINT"):
        pair("count-result-" + dtype.lower(), f"SELECT CAST(COUNT(*) AS {dtype}) cnt FROM Event",
             f"SELECT CAST(COUNT(*) AS {dtype}) cnt FROM Event", count_context,
             expected={"result_cast": dtype})
        pair("rank-result-" + dtype.lower(), f"SELECT CAST(ROW_NUMBER() OVER(ORDER BY ParentId) AS {dtype}) rn FROM Parent",
             f"SELECT CAST(ROW_NUMBER() OVER(ORDER BY ParentId) AS {dtype}) rn FROM Parent", rank_context,
             expected={"result_cast": dtype})
    pair("count-result-parameter", "SELECT CAST(COUNT(@Value) AS INT) cnt FROM Event",
         "SELECT CAST(COUNT(:Value) AS INT) cnt FROM Event", replace(count_context, parameters={"Value": "INT"}),
         expected={"result_cast": "INT", "parameter_uses": {"Value": 1}})
    pair("count-null-column", "SELECT COUNT(ParentId) cnt FROM Event", "SELECT COUNT(ParentId) cnt FROM Event",
         count_context, expected={"count_width": True})
    count_query = "SELECT CAST(COUNT(*) AS INT) cnt FROM Event"
    rank_query = "SELECT CAST(ROW_NUMBER() OVER(ORDER BY ParentId) AS BIGINT) rn FROM Parent"
    for label, bound in (("missing", None), ("large", 2**31), ("boolean", True)):
        pair("count-result-bound-" + label, count_query, count_query, ProbeContext(max_group_rows=bound), "count_bound")
        pair("rank-result-bound-" + label, rank_query, rank_query,
             replace(rank_context, max_partition_rows=bound), "partition_bound")
    pair("rank-result-order", rank_query, rank_query, ProbeContext(max_partition_rows=1000), "unique_order")
    for name, query, context, rejection in (
        ("count-result-smallint", "SELECT CAST(COUNT(*) AS SMALLINT) cnt FROM Event", count_context, "result_cast_type"),
        ("rank-result-smallint", "SELECT CAST(ROW_NUMBER() OVER(ORDER BY ParentId) AS SMALLINT) rn FROM Parent", rank_context, "result_cast_type"),
        ("count-result-window", "SELECT CAST(COUNT(*) OVER() AS INT) cnt FROM Event", count_context, "window_shape"),
        ("count-result-nested", "SELECT CAST(CAST(COUNT(*) AS INT) AS BIGINT) cnt FROM Event", count_context, "integer_domain"),
        ("count-result-sum", "SELECT CAST(SUM(Amount) AS INT) cnt FROM Event", count_context, "unsupported_node"),
        ("count-result-nested-aggregate", "SELECT CAST(COUNT(CAST(COUNT(*) AS INT)) AS INT) cnt FROM Event", count_context, "count_operand"),
        ("count-result-qualified-star", "SELECT CAST(COUNT(e.*) AS INT) cnt FROM Event e", count_context, "count_operand"),
    ):
        pair(name, query, query, context, rejection)
    assert len(result) == 40
    return result


def verify(case: Case, result: dict[str, object]) -> int:
    """Erwartung und Ziel-AST unabhängig von den einzelnen Mutationsschritten prüfen."""
    checks = 0

    def require(condition: object, label: str) -> None:
        nonlocal checks
        if not condition:
            raise AssertionError(f"{case.name}: {label}; status={result.get('status')}, code={result.get('code')}")
        checks += 1

    if case.rejection:
        require(result["status"] in ("unsupported", "requires_context"), "negative-status")
        require(result.get("code") == case.rejection, "negative-reason")
        require(result["sql"] is None, "no-partial-sql")
        require(result["rules"] == [] and result["parameters"] == [] and result["cast_types"] == [], "no-partial-contract")
        return checks
    require(result["status"] == "rewritten_in_spike", "positive-status")
    target = "databricks" if case.source == "tsql" else "tsql"
    tree = sqlglot.parse_one(str(result["sql"]), read=target, error_level=ErrorLevel.RAISE)
    require(isinstance(tree, exp.Select) and not list(tree.find_all(exp.Command)), "target-select-ast")
    source_tree = sqlglot.parse_one(case.query, read=case.source, error_level=ErrorLevel.RAISE)

    def value_literals(root: exp.Expr) -> Counter:
        values = Counter()
        values[("NULL", "")] = len(list(root.find_all(exp.Null)))
        for literal in root.find_all(exp.Literal):
            parent = literal.parent
            within_type = False
            while parent is not None:
                if isinstance(parent, exp.DataType):
                    within_type = True
                    break
                parent = parent.parent
            if not within_type:
                sign = "-" if isinstance(literal.parent, exp.Neg) else ""
                values[(literal.is_string, sign + literal.this)] += 1
        return values

    require(value_literals(source_tree) == value_literals(tree), "all-value-literals-retained")
    require(Counter((node.catalog, node.db, node.name) for node in source_tree.find_all(exp.Table))
            == Counter((node.catalog, node.db, node.name) for node in tree.find_all(exp.Table)), "relation-references-retained")
    expected = case.expected
    if "result_cast" in expected:
        casts = list(tree.find_all(exp.Cast))
        require(len(casts) == 1 and casts[0].to.this.name == expected["result_cast"], "single-explicit-result-cast")
        require(isinstance(casts[0].this, (exp.Count, exp.Window)), "result-cast-operand-retained")
    if "join" in expected:
        lateral = next(tree.find_all(exp.Lateral))
        join = lateral.parent
        cross = expected["join"] == "cross"
        if target == "tsql":
            require(lateral.args.get("cross_apply") is cross, "apply-outer-cross-retained")
            require(join.args.get("on") is None and not join.side, "no-leftover-join-condition")
        else:
            require(join.kind == "CROSS" if cross else join.side == "LEFT", "lateral-outer-cross-retained")
            require(join.args.get("on") is None if cross else isinstance(join.args.get("on"), exp.Boolean) and join.args["on"].this is True,
                    "neutral-on-only")
            if not cross:
                require(" ON TRUE" in str(result["sql"]), "explicit-neutral-condition-emitted")
    if "limits" in expected:
        require([int(node.expression.this) for node in tree.find_all(exp.Limit)] == expected["limits"], "limit-value-retained")
    if "parameter_uses" in expected:
        native_class = exp.Placeholder if target == "databricks" else exp.Parameter
        foreign_class = exp.Parameter if target == "databricks" else exp.Placeholder
        uses = Counter(node.this if target == "databricks" else node.this.name for node in tree.find_all(native_class))
        require(dict(uses) == expected["parameter_uses"], "native-marker-use-count")
        require(not list(tree.find_all(foreign_class)), "no-foreign-marker-in-ast")
        require({item["name"] for item in result["parameters"]} == set(uses), "parameter-metadata-not-duplicated")
    if "text" in expected:
        require(expected["text"] in [node.this for node in tree.find_all(exp.Literal) if node.is_string], "parameter-looking-literal-untouched")
    if "cast_kinds" in expected:
        require([node.to.this.name for node in tree.find_all(exp.Cast)] == expected["cast_kinds"], "cast-target-kinds")
    if "decimal" in expected:
        dtype = next(node.to for node in tree.find_all(exp.Cast) if node.to.this == exp.DType.DECIMAL)
        require([int(item.this.this) for item in dtype.expressions] == expected["decimal"], "decimal-precision-scale")
    if "ntz" in expected:
        dtype = next(tree.find_all(exp.Cast)).to
        require(dtype.this == (exp.DType.TIMESTAMPNTZ if target == "databricks" else exp.DType.DATETIME2), "explicit-ntz-type-family")
        if target == "tsql":
            require([int(item.this.this) for item in dtype.expressions] == [6], "explicit-target-time-precision")
    if "count_width" in expected:
        count = next(tree.find_all(exp.Count))
        require(isinstance(count.parent, exp.Cast) and count.parent.to.this == exp.DType.INT if target == "databricks" else count.args.get("big_int") is True,
                "count-result-width")
    if "count_big" in expected:
        require(not isinstance(next(tree.find_all(exp.Count)).parent, exp.Cast), "big-count-not-narrowed")
    if "ranking_width" in expected:
        window = next(tree.find_all(exp.Window))
        require(isinstance(window.parent, exp.Cast) and window.parent.to.this == (exp.DType.BIGINT if target == "databricks" else exp.DType.INT),
                "ranking-result-width")
    if "cutoff" in expected:
        predicate = next(tree.find_all(exp.LTE))
        require(predicate.this.sql() == "e.EventTime" and predicate.expression.sql() == "p.CutoffTime", "cutoff-correlation-retained")
        require(not list(tree.find_all(exp.RowNumber)), "no-unsafe-window-decorrelation")
    return checks


def verify_roundtrip(case: Case, forward: dict[str, object]) -> tuple[dict[str, object], int]:
    """Werte-/Parametererhalt und insbesondere die öffentliche Ergebnisbreite prüfen."""
    context = replace(case.context, parameters={p["name"]: p["target_type"] for p in forward["parameters"]})
    back = rewrite(str(forward["sql"]), "databricks" if case.source == "tsql" else "tsql", context)
    checks = 0

    def require(condition, label):
        nonlocal checks
        if not condition:
            raise AssertionError(case.name + ": roundtrip-" + label)
        checks += 1

    require(back["status"] == "rewritten_in_spike", "status")
    tree = sqlglot.parse_one(str(back["sql"]), read=case.source, error_level=ErrorLevel.RAISE)
    require(isinstance(tree, exp.Select), "select")
    native = exp.Parameter if case.source == "tsql" else exp.Placeholder
    names = Counter(node.this.name if case.source == "tsql" else node.this for node in tree.find_all(native))
    original = sqlglot.parse_one(case.query, read=case.source)
    original_names = Counter(node.this.name if case.source == "tsql" else node.this for node in original.find_all(native))
    require(names == original_names, "parameter-use-count")
    require({p["name"]: exp.DataType.build(p["target_type"], dialect=case.source) for p in back["parameters"]}
            == {name: exp.DataType.build(dtype, dialect=case.source) for name, dtype in case.context.parameters.items()},
            "parameter-types")
    name = case.name.split("/")[0]
    if name in ("count-width", "count-parameter-copy", "count-null-column"):
        count = next(tree.find_all(exp.Count))
        if case.source == "tsql":
            require(count.args.get("big_int") is True and isinstance(count.parent, exp.Cast)
                    and count.parent.to.this == exp.DType.INT, "count-int32-restored")
        else:
            require(not isinstance(count.parent, exp.Cast), "count-int64-kept")
    if name == "ranking-width":
        window = next(tree.find_all(exp.Window))
        require(isinstance(window.parent, exp.Cast)
                and window.parent.to.this == (exp.DType.BIGINT if case.source == "tsql" else exp.DType.INT), "ranking-width-restored")
        require(len(list(tree.find_all(exp.Cast))) == 1, "no-nested-ranking-casts")
    if "result_cast" in case.expected:
        casts = list(tree.find_all(exp.Cast))
        require(len(casts) == 1 and casts[0].to.this.name == case.expected["result_cast"], "explicit-result-width-kept")
    return back, checks


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if sqlglot.__version__ != PIN:
        parser.error(f"Erfordert SQLGlot {PIN}")
    output = args.output.resolve()
    if not output.is_relative_to(ROOT / ".runtime"):
        parser.error("Bericht ausschließlich unter .runtime/")
    fixtures = cases() + result_cast_cases()
    observations = []
    failures = []
    assertions = 0
    roundtrips = []
    for case in fixtures:
        outcome = rewrite(case.query, case.source, case.context)
        try:
            assertions += verify(case, outcome)
            if case.rejection is None:
                back, checks = verify_roundtrip(case, outcome)
                assertions += checks
                roundtrips.append(dict(name=case.name, result=back))
        except (AssertionError, StopIteration, KeyError, TypeError) as error:
            failures.append(case.name + ": " + str(error))
        observations.append(dict(name=case.name, source=case.source, expected_rejection=case.rejection, result=outcome))
    summary = dict(cases=len(fixtures), positive=sum(case.rejection is None for case in fixtures),
                   negative=sum(case.rejection is not None for case in fixtures), assertions=assertions,
                   roundtrips=len(roundtrips),
                   outcomes=dict(Counter(str(item["result"]["status"]) for item in observations)), failures=failures)
    bindings = {name: hashlib.sha256((Path(__file__).parent / name).read_bytes()).hexdigest()
                for name in ("rules_probe.py", "run_rule_spike.py", "run_spike.py", "requirements.txt")}
    report = dict(sqlglot_version=PIN, python_version=sys.version.split()[0], source_hashes=bindings,
                  summary=summary, cases=observations, roundtrips=roundtrips,
                  engine_execution="not executed", performance_measurement="not executed")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=True))
    return int(bool(failures))


if __name__ == "__main__":
    raise SystemExit(main())
