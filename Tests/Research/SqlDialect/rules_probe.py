"""Interne Researchregeln für feste Fixtures; keine freigegebene V1-API.

Geprüft werden AST-Umschreibungen und explizite Ablehnungen. Es gibt keinen
Katalogbinder, keine Engineverbindung und keine allgemeine Semantikzusage.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date, datetime
from decimal import Decimal, InvalidOperation, localcontext
import logging
import re

import sqlglot
from sqlglot import ErrorLevel, exp

from run_spike import Capture, PIN


INT32_MAX = 2**31 - 1
INTEGER_RANGES = {
    exp.DType.UTINYINT: (0, 255),
    exp.DType.TINYINT: (-128, 127),
    exp.DType.SMALLINT: (-32768, 32767),
    exp.DType.INT: (-2**31, INT32_MAX),
    exp.DType.BIGINT: (-2**63, 2**63 - 1),
}
NAME = re.compile(r"[A-Za-z_][A-Za-z_0-9]*\Z")
NUMBER = re.compile(r"-?[0-9]+(?:\.[0-9]+)?\Z")
WALLCLOCK = re.compile(r"[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.([0-9]{1,6}))?\Z")


@dataclass(frozen=True)
class ProbeContext:
    """Nur deklarierter synthetischer Kontext, keine ermittelten Istwerte."""

    parameters: dict[str, str] = field(default_factory=dict)
    unique_orders: frozenset[tuple[str, ...]] = frozenset()
    max_group_rows: int | None = None
    max_partition_rows: int | None = None
    ntz6_profile: bool = False


class Reject(Exception):
    def __init__(self, code: str, detail: str, context: bool = False):
        super().__init__(detail)
        self.code = code
        self.status = "requires_context" if context else "unsupported"


def dimensions(dtype: exp.DataType) -> list[int]:
    result = []
    for parameter in dtype.expressions:
        literal = parameter.this
        if not isinstance(literal, exp.Literal) or not literal.is_int:
            raise Reject("type_dimensions", "Explizite ganzzahlige Typdimensionen erforderlich")
        result.append(int(literal.this))
    return result


def mapped_type(dtype: exp.DataType, source: str, target: str, context: ProbeContext) -> exp.DataType:
    """Bewusst kleine Typmenge; Defaultbreiten und Rundung nicht erraten."""
    kind, dims = dtype.this, dimensions(dtype)
    if kind in INTEGER_RANGES:
        if (source == "tsql" and kind == exp.DType.TINYINT) or (source == "databricks" and kind == exp.DType.UTINYINT):
            raise Reject("unsupported_type", "Integeralias gehört nicht zum Quellprofil")
        if dims:
            raise Reject("type_dimensions", "Keine Integer-Displaybreite im Spike")
        return exp.DataType.build("SMALLINT" if kind in (exp.DType.UTINYINT, exp.DType.TINYINT) else kind.name,
                                  dialect=target)
    if kind == exp.DType.DECIMAL:
        if len(dims) != 2 or not 1 <= dims[0] <= 38 or not 0 <= dims[1] <= dims[0]:
            raise Reject("decimal_dimensions", "DECIMAL benötigt gültige explizite Precision/Scale")
        return exp.DataType.build(f"DECIMAL({dims[0]},{dims[1]})", dialect=target)
    if kind == exp.DType.DATE and not dims:
        return dtype.copy()
    if kind == (exp.DType.DATETIME2 if source == "tsql" else exp.DType.TIMESTAMPNTZ):
        precision = dims[0] if len(dims) == 1 else (6 if source == "databricks" and not dims else None)
        if precision is None or not 0 <= precision <= 6:
            raise Reject("timestamp_precision", "Nur explizites DATETIME2(0..6) beziehungsweise NTZ-Präzision 6")
        if source == "databricks" and precision != 6:
            raise Reject("timestamp_precision", "Databricks-Teilprofil ist ausschließlich NTZ(6)")
        if not context.ntz6_profile:
            raise Reject("timestamp_context", "Gemeinsames zeitzonenloses Sechserprofil fehlt", True)
        return exp.DataType.build("TIMESTAMP_NTZ" if target == "databricks" else "DATETIME2(6)", dialect=target)
    raise Reject("unsupported_type", f"Typ {kind.name} benötigt einen gesonderten Vertrag")


def parameter_name(node: exp.Expr, source: str) -> str:
    if source == "tsql" and isinstance(node, exp.Parameter) and isinstance(node.this, exp.Var):
        name = node.this.name
    elif source == "databricks" and isinstance(node, exp.Placeholder) and isinstance(node.this, str):
        name = node.this
    else:
        raise Reject("parameter_marker", "Nur einfache benannte native Parameter; keine System-/Alt-/Positionsmarker")
    if not NAME.fullmatch(name):
        raise Reject("parameter_name", "Parametername liegt außerhalb des ASCII-Identifierprofils")
    return name


def numeric_literal(node: exp.Expr) -> Decimal | None:
    if isinstance(node, exp.Neg):
        child = numeric_literal(node.this)
        return -child if child is not None else None
    if isinstance(node, exp.Literal) and not node.is_string and NUMBER.fullmatch(node.this):
        return Decimal(node.this)
    return None


def require_count_bound(context: ProbeContext) -> None:
    if type(context.max_group_rows) is not int or not 0 <= context.max_group_rows <= INT32_MAX:
        raise Reject("count_bound", "COUNT benötigt zugesicherte Gruppengröße innerhalb INT", True)


def check_count(count: exp.Count) -> None:
    if isinstance(count.parent, exp.Window):
        raise Reject("window_count", "Window-COUNT liegt außerhalb des kleinen Regelspikes")
    if type(count.this) not in (exp.Star, exp.Column, exp.Literal, exp.Null, exp.Cast, exp.Parameter, exp.Placeholder) or count.expressions:
        raise Reject("count_operand", "Nur einfaches skalares COUNT-Argument")
    if (isinstance(count.this, exp.Column) and count.this.is_star) or list(count.this.find_all(exp.AggFunc, exp.Window, exp.Subquery)):
        raise Reject("count_operand", "Keine geschachtelten Aggregate/Windows/Subqueries oder qualifizierten Sterne im COUNT")


def check_ranking(window: exp.Window, context: ProbeContext) -> None:
    if not isinstance(window.this, exp.RowNumber) or window.args.get("spec"):
        raise Reject("window_shape", "Nur einfaches ROW_NUMBER-Ranking")
    require_unique(window.args.get("order"), context)
    if type(context.max_partition_rows) is not int or not 1 <= context.max_partition_rows <= INT32_MAX:
        raise Reject("partition_bound", "Gemeinsame INTEGER-Partitionsgrenze fehlt", True)


def check_cast_domain(cast: exp.Cast, source: str, context: ProbeContext) -> str | None:
    """Eine Verbreiterung darf keine im Quellcast ungültigen Werte zulassen.

    Literale/Parameter und ausschließlich begrenzte COUNT-/ROW_NUMBER-Ergebnisse
    sind prüfbar. Allgemeine Spalten-/Ausdrucksbindung bleibt ausgeschlossen.
    """
    dtype = cast.to
    value = cast.this
    if isinstance(value, (exp.Count, exp.Window)):
        if dtype.this not in (exp.DType.INT, exp.DType.BIGINT) or dimensions(dtype):
            raise Reject("result_cast_type", "Ergebniscaste nur auf INT/BIGINT im gemeinsamen begrenzten Wertebereich")
        if isinstance(value, exp.Count):
            check_count(value)
            require_count_bound(context)
            return "bounded-count-result-cast"
        check_ranking(value, context)
        return "bounded-row-number-result-cast"
    if isinstance(value, exp.Null):
        return
    if isinstance(value, (exp.Parameter, exp.Placeholder)):
        name = parameter_name(value, source)
        if name not in context.parameters:
            raise Reject("parameter_type", f"Typdefinition für {name} fehlt", True)
        declared = exp.DataType.build(context.parameters[name], dialect=source)
        if declared != dtype:
            raise Reject("cast_domain", "Parametercast benötigt identischen deklarierten Quelltyp", True)
        return
    kind = dtype.this
    number = numeric_literal(value)
    if isinstance(value, exp.Column):
        raise Reject("cast_domain", "Spaltencasts benötigen den noch fehlenden Domänen-/Schemabinder", True)
    if kind in INTEGER_RANGES:
        low, high = INTEGER_RANGES[kind]
        if number is None or number != number.to_integral_value() or not low <= number <= high:
            raise Reject("integer_domain", "Quellcast nicht als gültige verlustfreie Ganzzahl belegt")
    elif kind == exp.DType.DECIMAL:
        precision, scale = dimensions(dtype)
        if number is None:
            raise Reject("cast_domain", "DECIMAL-Quellcast benötigt exaktes Literal", True)
        with localcontext() as decimal_context:
            decimal_context.prec = 100
            quantum = Decimal(1).scaleb(-scale)
            try:
                exact = number.quantize(quantum) == number
            except InvalidOperation:
                exact = False
            if not exact or abs(number) >= Decimal(10) ** (precision - scale):
                raise Reject("decimal_domain", "Rundung oder Überlauf im Quellcast nicht unterstützt")
    elif kind == exp.DType.DATE:
        try:
            if not isinstance(value, exp.Literal) or not value.is_string or not re.fullmatch(r"[0-9]{4}-[0-9]{2}-[0-9]{2}", value.this):
                raise ValueError()
            date.fromisoformat(value.this)
        except ValueError:
            raise Reject("date_domain", "Nur gültiges ISO-DATE-Literal im gemeinsamen Bereich") from None
    else:
        match = WALLCLOCK.fullmatch(value.this) if isinstance(value, exp.Literal) and value.is_string else None
        precision = dimensions(dtype)[0] if dtype.expressions else 6
        try:
            if match is None or len(match.group(1) or "") > precision:
                raise ValueError()
            datetime.fromisoformat(value.this)
        except ValueError:
            raise Reject("timestamp_domain", "Nur gültiges offsetfreies Literal ohne Präzisionsrundung") from None


ALLOWED_NODES = frozenset("Select From Table TableAlias Join Subquery Lateral Identifier Column Literal Neg Boolean Null Alias Star Where EQ GT GTE LT LTE NEQ And Or Not Is Paren Order Ordered Limit LimitOptions Cast DataType DataTypeParam Var Parameter Placeholder Count Group Having Window RowNumber With CTE".split())


def require_unique(order: exp.Order | None, context: ProbeContext) -> None:
    if order is None or not all(isinstance(item.this, exp.Column) for item in order.expressions):
        raise Reject("order_required", "Limit/Ranking benötigt einfache explizite ORDER-BY-Spalten", True)
    signature = tuple(item.this.sql() for item in order.expressions)
    if not signature or signature not in context.unique_orders:
        raise Reject("unique_order", "Eindeutigkeit der konkreten Sortierspalten fehlt", True)


def preflight(tree: exp.Expr, context: ProbeContext) -> None:
    if not isinstance(tree, exp.Select):
        raise Reject("query_shape", "Nur eine SELECT-Abfrage einschließlich nichtrekursiver CTEs")
    for node in tree.walk():
        if type(node).__name__ not in ALLOWED_NODES:
            raise Reject("unsupported_node", f"Knoten {type(node).__name__} liegt außerhalb des Researchprofils")
        if isinstance(node, exp.With) and node.args.get("recursive"):
            raise Reject("recursive_cte", "Rekursive CTEs nicht unterstützt")
        if isinstance(node, exp.Table) and not isinstance(node.this, exp.Identifier):
            raise Reject("table_function", "Keine ungebundene Tabellenfunktion")
        if isinstance(node, exp.RowNumber) and not isinstance(node.parent, exp.Window):
            raise Reject("window_shape", "ROW_NUMBER benötigt eine explizite OVER-Klausel")
        if isinstance(node, exp.Select):
            if node.args.get("into") or node.args.get("offset") or node.args.get("distinct"):
                raise Reject("select_option", "INTO/OFFSET/DISTINCT nicht im Researchprofil")
            for projection in node.expressions:
                if isinstance(projection, exp.Star) or (isinstance(projection, exp.Column) and projection.is_star):
                    raise Reject("projection_schema", "Sternprojektion benötigt einen noch fehlenden Schemabinder", True)
        if isinstance(node, exp.Limit):
            options = node.args.get("limit_options")
            if options and any(options.args.values()):
                raise Reject("limit_options", "PERCENT/WITH TIES/ROWS sind nicht erlaubt")
            literal = node.expression
            if not isinstance(literal, exp.Literal) or not literal.is_int:
                raise Reject("limit_literal", "Nur positive ganzzahlige Limitliterale")
            if not 1 <= int(literal.this) <= 1000:
                raise Reject("limit_range", "Limit liegt außerhalb des kleinen Spikeprofils 1..1000")
            if not isinstance(node.parent, exp.Select):
                raise Reject("limit_scope", "Limit nur an SELECT")
            require_unique(node.parent.args.get("order"), context)
    if len(list(tree.find_all(exp.Lateral))) > 1:
        raise Reject("lateral_depth", "Researchprofil erlaubt insgesamt eine laterale Stufe")


def normalize_lateral(tree: exp.Expr, source: str, query: str, rules: list[str]) -> None:
    for lateral in tree.find_all(exp.Lateral):
        join = lateral.parent
        if not isinstance(join, exp.Join) or not isinstance(lateral.this, exp.Subquery) or not isinstance(lateral.this.this, exp.Select):
            raise Reject("lateral_shape", "LATERAL/APPLY muss eine SELECT-Unterabfrage als rechten Joinoperand haben")
        alias = lateral.args.get("alias")
        if not alias or alias.args.get("columns"):
            raise Reject("lateral_alias", "Einfacher eindeutiger Relationsalias erforderlich")
        if source == "tsql":
            cross = lateral.args.get("cross_apply")
            if cross is None or join.args.get("on") is not None or join.side or join.kind:
                raise Reject("lateral_join", "Nur native CROSS/OUTER-APPLY-Formen als T-SQL-Quelle")
            lateral.set("cross_apply", None)
            join.set("side", None if cross else "LEFT")
            join.set("kind", "CROSS" if cross else None)
            join.set("on", None if cross else exp.Boolean(this=True))
            rules.append("apply-to-lateral-explicit-condition")
        else:
            neutral = isinstance(join.args.get("on"), exp.Boolean) and join.args["on"].this is True
            if join.side == "LEFT" and join.kind in ("", "OUTER") and neutral:
                # Der Provider ergänzt bei fehlendem ON intern TRUE. Für den
                # Researchvertrag muss ON TRUE deshalb auch im Tokenstrom
                # unmittelbar nach dem einfachen Alias stehen; Kommentare zählen nicht.
                alias_end = alias.this.meta.get("end")
                tokens = sqlglot.Dialect.get_or_raise(source).tokenize(query)
                following = [token for token in tokens if alias_end is not None and token.start > alias_end]
                if len(following) < 2 or [token.token_type.name for token in following[:2]] != ["ON", "TRUE"]:
                    raise Reject("lateral_condition", "Explizites ON TRUE erforderlich; Parserdefault reicht nicht")
                cross = False
            elif join.kind == "CROSS" and not join.side and join.args.get("on") is None:
                cross = True
            else:
                raise Reject("lateral_join", "Nur LEFT/ON TRUE oder CROSS/ohne ON; andere Prädikate bleiben gesperrt")
            lateral.set("cross_apply", cross)
            join.set("side", None)
            join.set("kind", None)
            join.set("on", None)
            rules.append("lateral-to-apply-neutral-join")


def rewrite(query: str, source: str, context: ProbeContext) -> dict[str, object]:
    """Interner Fixture-Einstieg mit geschlossenem Ergebnis bei jeder Ablehnung."""
    if sqlglot.__version__ != PIN:
        raise RuntimeError(f"Researchregeln erfordern SQLGlot {PIN}")
    result: dict[str, object] = {"status": "unsupported", "sql": None, "rules": [], "parameters": [], "cast_types": []}
    if source not in ("tsql", "databricks"):
        return dict(result, code="source_dialect")
    target = "databricks" if source == "tsql" else "tsql"
    capture = Capture()
    logger = logging.getLogger("sqlglot")
    propagate = logger.propagate
    logger.propagate = False
    logger.addHandler(capture)
    try:
        if len(query.encode("utf-8")) > 16384:
            raise Reject("input_size", "Kleine Researcheingaben sind auf 16 KiB beschränkt")
        trees = sqlglot.parse(query, read=source, error_level=ErrorLevel.RAISE)
        if len(trees) != 1 or trees[0] is None:
            raise Reject("statement_count", "Genau eine Abfrage erforderlich")
        tree = trees[0]
        preflight(tree, context)
        rules: list[str] = []
        normalize_lateral(tree, source, query, rules)
        parameters = list(tree.find_all(exp.Parameter, exp.Placeholder))
        names = [parameter_name(node, source) for node in parameters]
        unique_names = sorted(set(names))
        if len({name.casefold() for name in unique_names}) != len(unique_names):
            raise Reject("parameter_collision", "Casekollision zwischen Parametern")
        if len(unique_names) > 64:
            raise Reject("parameter_count", "Höchstens 64 Parameter im kleinen Researchprofil")
        parameter_types: dict[str, exp.DataType] = {}
        for name in unique_names:
            if name not in context.parameters:
                raise Reject("parameter_type", f"Expliziter Typ für {name} fehlt", True)
            parameter_types[name] = mapped_type(exp.DataType.build(context.parameters[name], dialect=source), source, target, context)
        cast_types = []
        for cast in list(tree.find_all(exp.Cast)):
            original_type = cast.to.sql(dialect=source)
            mapped = mapped_type(cast.to, source, target, context)
            result_rule = check_cast_domain(cast, source, context)
            cast.set("to", mapped)
            cast.type = mapped.copy()
            cast_types.append({"source_type": original_type, "target_type": mapped.sql(dialect=target)})
            rules.append("explicit-cast-common-domain")
            if result_rule:
                rules.append(result_rule)
        # Vor kopierenden Count-/Window-Umschreibungen alle Parameter ersetzen,
        # damit keine abgetrennte alte Teilstruktur statt der Ausgabe geändert wird.
        for node, name in zip(parameters, names):
            node.replace(exp.Placeholder(this=name) if target == "databricks" else exp.Parameter(this=exp.Var(this=name)))
        for count in list(tree.find_all(exp.Count)):
            check_count(count)
            if source == "tsql" and not count.args.get("big_int"):
                require_count_bound(context)
                # Ein bereits geprüfter Ergebniscaste bestimmt den öffentlichen
                # Typ. Keine zusätzliche INT-Hülle unter einem äußeren BIGINT.
                if not isinstance(count.parent, exp.Cast):
                    count.replace(exp.Cast(this=count.copy(), to=exp.DataType.build("INT")))
                    rules.append("count32-result-cast")
        for window in list(tree.find_all(exp.Window)):
            check_ranking(window, context)
            if not isinstance(window.parent, exp.Cast):
                window.replace(exp.Cast(this=window.copy(), to=exp.DataType.build("BIGINT" if source == "tsql" else "INT")))
                rules.append("row-number-result-width")
        if parameters:
            rules.append("typed-native-parameter-markers")
        output = tree.sql(dialect=target, unsupported_level=ErrorLevel.RAISE)
        target_trees = sqlglot.parse(output, read=target, error_level=ErrorLevel.RAISE)
        if capture.messages or len(target_trees) != 1 or target_trees[0] is None or list(target_trees[0].find_all(exp.Command)):
            raise Reject("provider_diagnostic", "Providerdiagnostik oder unvollständige Zielsyntax")
        result.update(status="rewritten_in_spike", sql=output, rules=rules, cast_types=cast_types,
                      parameters=[{"name": name, "source_type": context.parameters[name],
                                   "target_type": parameter_types[name].sql(dialect=target)} for name in unique_names])
    except Reject as error:
        result.update(status=error.status, code=error.code, detail=str(error))
    except sqlglot.errors.SqlglotError as error:
        result.update(status="unsupported", code="provider_error", detail=type(error).__name__)
    finally:
        logger.removeHandler(capture)
        logger.propagate = propagate
    return result
