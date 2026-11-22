"""Translate the first explicitly bound, integer-only SELECT profile offline."""

import argparse
from datetime import date, timedelta
import json
import re
from pathlib import Path

import sqlglot
from sqlglot import Dialect, ErrorLevel, exp
from sqlglot.errors import ParseError, TokenError


PIN = "30.23.0"
MAX_SQL_BYTES = 16_384
MAX_CONTEXT_BYTES = 65_536
MAX_TOKENS = 512
MAX_DEPTH = 16
NAME = re.compile(r"[A-Za-z_][A-Za-z_0-9]{0,127}\Z")
COMPARISONS = {exp.EQ: "=", exp.NEQ: "<>", exp.LT: "<", exp.LTE: "<=", exp.GT: ">", exp.GTE: ">="}
DOMAIN_TYPES = ("INT", "BIGINT", "DATE")


class Rejected(Exception):
    def __init__(self, status, code):
        self.status = status
        self.code = code


def require(condition, code, status="unsupported"):
    if not condition:
        raise Rejected(status, code)


def shape(node, cls, *names):
    require(type(node) is cls and not any(value for key, value in node.args.items() if key not in names),
            "query_shape")


def identifier(node):
    shape(node, exp.Identifier, "this", "quoted")
    require(isinstance(node.this, str) and NAME.fullmatch(node.this), "identifier")
    return node.this


def quote(name, dialect):
    return f"[{name}]" if dialect == "tsql" else f"`{name}`"


class SelectBinding:
    def __init__(self, source, context):
        self.source = source
        self.target = "databricks" if source == "tsql" else "tsql"
        self.context = context
        self.relations = {}
        self.base_relations = set()
        self.ctes = {}
        self.parameters = {}
        self.capabilities = set()
        self.assumptions = []

    def relation(self, table):
        if type(table) is exp.Subquery:
            shape(table, exp.Subquery, "this", "alias")
            table_alias = table.args.get("alias")
            shape(table_alias, exp.TableAlias, "this")
            alias = identifier(table_alias.this)
            self.require_new_alias(alias)
            sql, schema = self.child().query(table.this, allow_ctes=False)
            self.relations[alias] = ({column["name"]: column for column in schema}, False)
            return f"(\n{sql}\n) AS {quote(alias, self.target)}", alias
        shape(table, exp.Table, "this", "db", "catalog", "alias")
        parts = tuple(identifier(table.args[key]) for key in ("catalog", "db", "this") if table.args.get(key))
        table_alias = table.args.get("alias")
        shape(table_alias, exp.TableAlias, "this")
        alias = identifier(table_alias.this)
        self.require_new_alias(alias)
        if len(parts) == 1:
            columns = self.ctes.get(parts[0])
            require(columns is not None, "unbound_cte", "requires_context")
            self.relations[alias] = (columns, False)
            return self.qualified(parts, alias), alias
        source_width = 2 if self.source == "tsql" else 3
        require(len(parts) == source_width, "qualified_relation", "requires_context")
        mappings = self.context.get("relations", [self.context.get("relation")])
        require(isinstance(mappings, list), "relation_contract", "invalid_input")
        matches = [entry for entry in mappings if isinstance(entry, dict) and entry.get("source") == list(parts)]
        require(len(matches) == 1, "relation_mapping", "requires_context")
        binding = matches[0]
        target = binding.get("target")
        require(isinstance(target, list) and len(target) == 5 - source_width
                and all(isinstance(part, str) and NAME.fullmatch(part) for part in target),
                "target_relation", "requires_context")
        columns = binding.get("columns")
        require(isinstance(columns, dict) and bool(columns), "relation_columns", "requires_context")
        self.relations[alias] = (columns, False)
        self.base_relations.add(alias)
        return self.qualified(target, alias), alias

    def qualified(self, parts, alias):
        return ".".join(quote(part, self.target) for part in parts) + " AS " + quote(alias, self.target)

    def require_new_alias(self, alias):
        require(alias.casefold() not in {key.casefold() for key in self.relations}, "duplicate_relation_alias")

    def join(self, node):
        shape(node, exp.Join, "this", "on", "side", "kind")
        if type(node.this) is exp.Lateral:
            return self.lateral_join(node)
        side = node.args.get("side") or ""
        kind = node.args.get("kind") or ""
        on = node.args.get("on")
        if kind == "CROSS":
            require(not side and on is None, "cross_join")
        else:
            require(side in ("", "LEFT", "RIGHT", "FULL") and kind in ("", "INNER", "OUTER")
                    and (not side or kind != "INNER") and (side or kind != "OUTER")
                    and on is not None, "join_shape")
        relation, alias = self.relation(node.this)
        if kind == "CROSS":
            return "CROSS JOIN " + relation
        predicate = self.predicate(on)
        for key, (columns, nullable) in self.relations.items():
            if (key == alias and side in ("LEFT", "FULL")) or (key != alias and side in ("RIGHT", "FULL")):
                self.relations[key] = (columns, True)
        return f"{side or 'INNER'} JOIN {relation} ON {predicate}"

    def lateral_join(self, join):
        require(self.context.get("lateral_select") is True, "lateral_target_capability", "requires_context")
        require("lateral_select" not in self.capabilities, "lateral_count")
        self.capabilities.add("lateral_select")
        lateral = join.this
        shape(lateral, exp.Lateral, "this", "alias", "cross_apply")
        side, kind, on = (join.args.get(key) for key in ("side", "kind", "on"))
        if self.source == "tsql":
            cross = lateral.args.get("cross_apply")
            require(type(cross) is bool and not side and not kind and on is None, "apply_shape")
        else:
            cross = kind == "CROSS"
            if cross:
                require(not side and on is None, "lateral_cross_join")
            else:
                require(side == "LEFT" and kind in (None, "OUTER"), "lateral_left_join")
                shape(on, exp.Boolean, "this")
                require(on.this is True, "lateral_join_condition")
        alias_node = lateral.args.get("alias")
        shape(alias_node, exp.TableAlias, "this")
        alias = identifier(alias_node.this)
        self.require_new_alias(alias)
        shape(lateral.this, exp.Subquery, "this")
        query = lateral.this.this
        shape(query, exp.Select, "expressions", "from_", "where")
        from_node = query.args.get("from_")
        shape(from_node, exp.From, "this")
        shape(from_node.this, exp.Table, "this", "db", "catalog", "alias")
        local_alias = from_node.this.args.get("alias")
        shape(local_alias, exp.TableAlias, "this")
        local_name = identifier(local_alias.this)
        for projection in query.expressions:
            require(all(column.table == local_name for column in projection.find_all(exp.Column)), "lateral_projection")
        where = query.args.get("where")
        if where is not None:
            shape(where, exp.Where, "this")
            correlation = where.this
            while type(correlation) is exp.Paren:
                shape(correlation, exp.Paren, "this")
                correlation = correlation.this
            shape(correlation, exp.EQ, "this", "expression")
            left, right = correlation.this, correlation.expression
            shape(left, exp.Column, "this", "table")
            shape(right, exp.Column, "this", "table")
            require((left.table == local_name and right.table in self.relations)
                    or (right.table == local_name and left.table in self.relations), "lateral_correlation")
        member = self.child()
        member.relations = self.relations.copy()
        member.base_relations = self.base_relations.copy()
        sql, schema = member.query(query, allow_ctes=False)
        self.relations[alias] = ({column["name"]: column for column in schema}, not cross)
        relation = f"(\n{sql}\n) AS {quote(alias, self.target)}"
        if self.target == "tsql":
            return ("CROSS APPLY " if cross else "OUTER APPLY ") + relation
        return ("CROSS JOIN LATERAL " if cross else "LEFT JOIN LATERAL ") + relation + ("" if cross else " ON TRUE")

    def child(self):
        member = SelectBinding(self.source, self.context)
        member.ctes = self.ctes
        member.parameters = self.parameters
        member.capabilities = self.capabilities
        member.assumptions = self.assumptions
        return member

    def with_clause(self, node):
        shape(node, exp.With, "expressions")
        require(len(node.expressions) <= 16, "cte_count", "limit_exceeded")
        definitions = []
        for entry in node.expressions:
            shape(entry, exp.CTE, "this", "alias")
            alias = entry.args.get("alias")
            shape(alias, exp.TableAlias, "this")
            name = identifier(alias.this)
            require(name.casefold() not in {key.casefold() for key in self.ctes}, "duplicate_cte")
            sql, schema = self.child().query(entry.this, allow_ctes=False)
            self.ctes[name] = {column["name"]: column for column in schema}
            definitions.append(f"{quote(name, self.target)} AS (\n{sql}\n)")
        require(bool(definitions), "cte_shape")
        return "WITH " + ",\n".join(definitions) + "\n"

    def operand(self, node):
        if type(node) is exp.Column:
            shape(node, exp.Column, "this", "table")
            require(node.args.get("table") is not None, "column_qualifier", "requires_context")
            alias = identifier(node.args["table"])
            require(alias in self.relations, "column_qualifier", "requires_context")
            name = identifier(node.this)
            columns, outer_nullable = self.relations[alias]
            sql_type, nullable = self.column_contract(columns.get(name))
            return f"{quote(alias, self.target)}.{quote(name, self.target)}", sql_type, nullable or outer_nullable
        if type(node) in (exp.Parameter, exp.Placeholder):
            if self.source == "tsql":
                shape(node, exp.Parameter, "this")
                shape(node.this, exp.Var, "this")
                name = node.this.this
            else:
                shape(node, exp.Placeholder, "this")
                name = node.this
            require(isinstance(name, str) and NAME.fullmatch(name), "parameter_name")
            declarations = self.context.get("parameters", {})
            require(isinstance(declarations, dict), "parameter_contract", "invalid_input")
            sql_type, nullable = self.column_contract(declarations.get(name))
            self.parameters[name] = {"type": sql_type, "nullable": nullable}
            marker = (":" if self.target == "databricks" else "@") + name
            return f"CAST({marker} AS {sql_type})", sql_type, nullable
        if type(node) is exp.Cast:
            shape(node, exp.Cast, "this", "to")
            shape(node.to, exp.DataType, "this")
            target_type = node.to.this.name
            if type(node.this) is exp.Null:
                shape(node.this, exp.Null)
                require(target_type in DOMAIN_TYPES, "type_cast")
                return f"CAST(NULL AS {target_type})", target_type, True
            if target_type == "DATE" and type(node.this) is exp.Literal and node.this.is_string:
                value = self.date_literal(node.this.this)
                literal = value.isoformat()
                if self.target == "tsql":
                    literal = literal.replace("-", "")
                return f"CAST('{literal}' AS DATE)", "DATE", False
            operand, source_type, nullable = self.operand(node.this)
            require(target_type == source_type or (source_type, target_type) == ("INT", "BIGINT"), "integer_cast")
            return f"CAST({operand} AS {target_type})", target_type, nullable
        if type(node) is exp.Case:
            return self.searched_case(node)
        if type(node) in (exp.Year, exp.Month, exp.Day):
            shape(node, type(node), "this")
            value, nullable = self.date_operand(node.this)
            return f"{node.key.upper()}({value})", "INT", nullable
        if type(node) in (exp.DateAdd, exp.TsOrDsAdd, exp.DateDiff):
            return self.date_arithmetic(node)
        value = self.integer_literal(node)
        return f"CAST({value} AS INT)", "INT", False

    @staticmethod
    def integer_literal(node):
        negative = type(node) is exp.Neg
        if negative:
            shape(node, exp.Neg, "this")
            node = node.this
        shape(node, exp.Literal, "this", "is_string")
        require(not node.is_string and re.fullmatch(r"[0-9]{1,10}", node.this), "integer_literal")
        value = int(node.this) * (-1 if negative else 1)
        # The minimum INT has dialect-specific literal typing. Keep a shared range.
        require(-2_147_483_647 <= value <= 2_147_483_647, "integer_literal_range")
        return value

    def date_literal(self, value):
        iso = re.fullmatch(r"[0-9]{4}-[0-9]{2}-[0-9]{2}", value)
        compact = self.source == "tsql" and re.fullmatch(r"[0-9]{8}", value)
        require(iso or compact, "date_literal")
        if compact:
            value = f"{value[:4]}-{value[4:6]}-{value[6:]}"
        try:
            return date.fromisoformat(value)
        except ValueError:
            raise Rejected("invalid_input", "date_literal") from None

    def date_operand(self, node):
        if type(node) is exp.TsOrDsToDate:
            shape(node, exp.TsOrDsToDate, "this", "default_date")
            node = node.this
        if type(node) is exp.TimeStrToTime:
            shape(node, exp.TimeStrToTime, "this")
            node = node.this
        sql, sql_type, nullable = self.operand(node)
        require(sql_type == "DATE", "explicit_date_type")
        return sql, nullable

    def date_arithmetic(self, node):
        shape(node, type(node), "this", "expression", "unit", "big_int")
        unit = node.args.get("unit")
        shape(unit, exp.Var, "this")
        require(unit.this == "DAY" and not node.args.get("big_int"), "date_unit")
        if type(node) is exp.DateDiff:
            end, end_null = self.date_operand(node.this)
            start, start_null = self.date_operand(node.expression)
            sql = f"DATEDIFF(day, {start}, {end})" if self.target == "tsql" else f"DATEDIFF({end}, {start})"
            return sql, "INT", start_null or end_null
        source = node.this
        require(type(source) in (exp.Column, exp.Parameter, exp.Placeholder, exp.Cast), "date_add_source")
        if type(source) is exp.Cast:
            # Literal DATE casts or one same-type cast on a native DATE input.
            require(type(source.this) in (exp.Literal, exp.Null, exp.Column, exp.Parameter, exp.Placeholder),
                    "date_add_source")
        sql, nullable = self.date_operand(source)
        days = self.integer_literal(node.expression)
        if type(source) is exp.Cast and type(source.this) is exp.Literal:
            start = end = self.date_literal(source.this.this)
        elif type(source) is exp.Cast and type(source.this) is exp.Null:
            start = end = None
        else:
            anchor = source.this if type(source) is exp.Cast else source
            require(type(anchor) is not exp.Column or anchor.table in self.base_relations, "date_add_derived_range")
            start, end = self.date_domain()
        if start is not None:
            try:
                shift = timedelta(days=days)
                _ = start + shift, end + shift
            except OverflowError:
                raise Rejected("unsupported", "date_add_range") from None
        result = f"DATEADD(day, {days}, {sql})" if self.target == "tsql" else f"DATE_ADD({sql}, {days})"
        return result, "DATE", nullable

    def date_domain(self):
        bounds = self.context.get("date_domain")
        require(isinstance(bounds, list) and len(bounds) == 2 and all(isinstance(item, str) for item in bounds),
                "date_domain", "requires_context")
        start, end = [self.date_literal(item) for item in bounds]
        require(start <= end, "date_domain", "invalid_input")
        fact = {"date_domain": [start.isoformat(), end.isoformat()]}
        if fact not in self.assumptions:
            self.assumptions.append(fact)
        return start, end

    def searched_case(self, node):
        shape(node, exp.Case, "ifs", "default")
        cases = node.args.get("ifs")
        default = node.args.get("default")
        require(bool(cases) and default is not None, "explicit_case")
        else_sql, result_type, nullable = self.operand(default)
        branches = []
        for branch in cases:
            shape(branch, exp.If, "this", "true")
            then_sql, branch_type, branch_nullable = self.operand(branch.args["true"])
            require(branch_type == result_type, "case_type")
            nullable |= branch_nullable
            branches.append(f"WHEN {self.predicate(branch.this)} THEN {then_sql}")
        return f"CASE {' '.join(branches)} ELSE {else_sql} END", result_type, nullable

    def column_contract(self, declaration):
        require(isinstance(declaration, dict), "operand_type", "requires_context")
        sql_type = declaration.get("type")
        nullable = declaration.get("nullable")
        require(sql_type in DOMAIN_TYPES and type(nullable) is bool, "operand_contract", "requires_context")
        if sql_type == "DATE":
            self.date_domain()
        return sql_type, nullable

    def predicate(self, node, resolve=None):
        resolve = resolve or self.operand
        kind = type(node)
        if kind in (exp.And, exp.Or):
            shape(node, kind, "this", "expression")
            operator = "AND" if kind is exp.And else "OR"
            return f"({self.predicate(node.this, resolve)} {operator} {self.predicate(node.expression, resolve)})"
        if kind in (exp.Paren, exp.Not):
            shape(node, kind, "this")
            nested = self.predicate(node.this, resolve)
            return f"(NOT {nested})" if kind is exp.Not else f"({nested})"
        if kind is exp.In:
            shape(node, exp.In, "this", "expressions")
            left, left_type, _ = resolve(node.this)
            require(bool(node.expressions), "in_literal_list")
            members = []
            for item in node.expressions:
                # Implicit string-to-number casts and nonliteral lists have
                # different error and binding rules across the engines.
                members.append(self.in_literal(item, left_type, resolve))
            return f"({left} IN ({', '.join(members)}))"
        if kind is exp.Exists:
            shape(node, exp.Exists, "this")
            shape(node.this, exp.Select, "expressions", "from_", "where", "joins")
            sql, _ = self.child().query(node.this, allow_ctes=False)
            return f"(EXISTS (\n{sql}\n))"
        shape(node, kind, "this", "expression")
        require(kind in COMPARISONS or kind is exp.Is, "predicate")
        left, left_type, _ = resolve(node.this)
        if kind is exp.Is:
            shape(node.expression, exp.Null)
            return f"({left} IS NULL)"
        right, right_type, _ = resolve(node.expression)
        require(left_type == right_type, "mixed_type_comparison")
        return f"({left} {COMPARISONS[kind]} {right})"

    @staticmethod
    def in_literal(node, expected_type, resolve):
        literal = node
        if type(literal) is exp.Cast:
            shape(literal, exp.Cast, "this", "to")
            literal = literal.this
        if type(literal) is exp.Neg:
            shape(literal, exp.Neg, "this")
            literal = literal.this
        shape(literal, exp.Literal, "this", "is_string")
        sql, sql_type, _ = resolve(node)
        require(sql_type == expected_type, "in_literal_type")
        return sql

    def query(self, tree, allow_ctes=True):
        is_union = type(tree) is exp.Union
        if is_union:
            shape(tree, exp.Union, "this", "expression", "distinct", "with_")
            require(tree.args.get("distinct") is False, "union_all_required")
        else:
            shape(tree, exp.Select, "expressions", "from_", "where", "joins", "with_", "order", "limit",
                  "group", "having", "qualify")
            require(allow_ctes or (tree.args.get("order") is None and tree.args.get("limit") is None),
                    "nested_order")
        with_node = tree.args.get("with_")
        require(allow_ctes or with_node is None, "nested_cte")
        prefix = self.with_clause(with_node) if with_node is not None else ""
        if is_union:
            left_sql, left_schema = self.child().query(tree.this, allow_ctes=False)
            right_sql, right_schema = self.child().query(tree.expression, allow_ctes=False)
            require([column["type"] for column in left_schema] == [column["type"] for column in right_schema],
                    "union_schema")
            for left, right in zip(left_schema, right_schema, strict=True):
                left["nullable"] |= right["nullable"]
            return prefix + left_sql + "\nUNION ALL\n" + right_sql, left_schema
        sql, schema = self.select(tree)
        return prefix + sql, schema

    def select(self, tree):
        from_node = tree.args.get("from_")
        joins = tree.args.get("joins", [])
        require(from_node is not None or not joins, "join_from_required")
        from_sql = []
        if from_node is not None:
            shape(from_node, exp.From, "this")
            relation, _ = self.relation(from_node.this)
            from_sql.append("FROM " + relation)
            from_sql.extend(self.join(node) for node in joins)
        group = tree.args.get("group")
        having = tree.args.get("having")
        grouping = self.group_columns(group) if group is not None else []
        expressions = [*tree.expressions, *([having] if having is not None else [])]
        grouped = group is not None or any(item.find(exp.AggFunc) is not None for item in expressions)
        require(not grouped or from_node is not None, "aggregate_relation")
        require(having is None or grouped, "having_group")

        def resolve(node):
            return self.group_operand(node, grouping) if grouped else self.operand(node)

        outputs = []
        schema = []
        seen = set()
        for projection in tree.expressions:
            shape(projection, exp.Alias, "this", "alias")
            name = identifier(projection.args["alias"])
            require(name.casefold() not in seen, "duplicate_output")
            seen.add(name.casefold())
            value, sql_type, nullable = (resolve(projection.this) if grouped else self.projection(projection.this))
            outputs.append(f"{value} AS {quote(name, self.target)}")
            schema.append({"name": name, "type": sql_type, "nullable": nullable})
        require(bool(outputs), "projection_required")
        order = tree.args.get("order")
        limit = tree.args.get("limit")
        qualify = tree.args.get("qualify")
        ordering = self.ordering(order, schema) if order is not None else ""
        count = self.row_limit(limit, order) if limit is not None else None
        top = f"TOP ({count}) " if count is not None and self.target == "tsql" else ""
        source_sql = ""
        if from_sql:
            source_sql += "\n" + "\n".join(from_sql)
        where = tree.args.get("where")
        if where:
            shape(where, exp.Where, "this")
            source_sql += "\nWHERE " + self.predicate(where.this)
        if grouping:
            source_sql += "\nGROUP BY " + ", ".join(grouping)
        if having is not None:
            shape(having, exp.Having, "this")
            source_sql += "\nHAVING " + self.predicate(having.this, resolve)
        projection = ", ".join(outputs)
        if qualify is not None:
            require(not grouped and from_node is not None, "qualify_scope")
            projection, source_sql = self.qualify(qualify, outputs, schema, source_sql, tree.expressions)
        sql = "SELECT " + top + projection + source_sql
        require(len(self.parameters) <= 64 and len({name.casefold() for name in self.parameters}) == len(self.parameters),
                "parameter_inventory")
        if ordering:
            sql += "\nORDER BY " + ordering
        if count is not None and self.target == "databricks":
            sql += f"\nLIMIT {count}"
        return sql, schema

    def group_columns(self, node):
        shape(node, exp.Group, "expressions")
        keys = []
        for column in node.expressions:
            shape(column, exp.Column, "this", "table")
            key, _, _ = self.operand(column)
            require(key not in keys, "duplicate_group_key")
            keys.append(key)
        require(bool(keys), "group_key")
        return keys

    def group_operand(self, node, grouping):
        if type(node) in (exp.Min, exp.Max):
            shape(node, type(node), "this")
            shape(node.this, exp.Column, "this", "table")
            value, sql_type, nullable = self.operand(node.this)
            # An ungrouped aggregate also has a row when the input is empty.
            return f"{node.key.upper()}({value})", sql_type, nullable or not grouping
        if type(node) is exp.Count:
            return self.count(node)
        if type(node) is exp.Cast and type(node.this) is exp.Count:
            shape(node, exp.Cast, "this", "to")
            shape(node.to, exp.DataType, "this")
            value, source_type, _ = self.count(node.this)
            sql_type = node.to.this.name
            require(sql_type in ("INT", "BIGINT"), "aggregate_cast")
            if source_type == "BIGINT" and sql_type == "INT":
                self.count32_bound()
            return f"CAST({value} AS {sql_type})", sql_type, False
        require(all(self.operand(column)[0] in grouping for column in node.find_all(exp.Column)),
                "unbound_group_column")
        return self.operand(node)

    def ranking(self, node):
        shape(node, exp.Window, "this", "partition_by", "order", "over")
        shape(node.this, exp.RowNumber)
        require(node.args.get("over") == "OVER", "ranking_window")
        order = node.args.get("order")
        shape(order, exp.Order, "expressions")
        require(bool(order.expressions), "ranking_order")
        partition = node.args.get("partition_by") or []
        order_sql = []
        keys = []
        partition_sql = []
        for column in partition:
            value, key = self.ranking_key(column)
            partition_sql.append(value)
            keys.append(key)
        for item in order.expressions:
            shape(item, exp.Ordered, "this", "desc", "nulls_first")
            value, key = self.ranking_key(item.this)
            order_sql.append(value + (" DESC" if item.args.get("desc") else " ASC"))
            keys.append(key)
        require(len(keys) == len(set(keys)), "ranking_duplicate_key")
        bound = self.context.get("max_partition_rows")
        require(type(bound) is int and 0 <= bound <= 2_147_483_647, "ranking_cardinality", "requires_context")
        require(self.context.get("ranking_order") == keys, "ranking_unique", "requires_context")
        fact = {"max_partition_rows": bound, "ranking_order": keys}
        if fact not in self.assumptions:
            self.assumptions.append(fact)
        by = "PARTITION BY " + ", ".join(partition_sql) + " " if partition_sql else ""
        result_type = "BIGINT" if self.source == "tsql" else "INT"
        rank = f"ROW_NUMBER() OVER ({by}ORDER BY {', '.join(order_sql)})"
        return f"CAST({rank} AS {result_type})", result_type, False

    def projection(self, node):
        if type(node) is exp.Window:
            return self.ranking(node)
        if type(node) is exp.Cast and type(node.this) is exp.Window:
            shape(node, exp.Cast, "this", "to")
            shape(node.to, exp.DataType, "this")
            target_type = node.to.this.name
            require(target_type in ("INT", "BIGINT"), "ranking_cast")
            ranked, _, _ = self.ranking(node.this)
            return f"CAST({ranked} AS {target_type})", target_type, False
        return self.operand(node)

    def ranking_key(self, column):
        shape(column, exp.Column, "this", "table")
        sql, _, nullable = self.operand(column)
        require(not nullable, "ranking_nullable_key")
        return sql, f"{column.table}.{column.name}"

    def qualify(self, node, outputs, schema, source_sql, projections):
        shape(node, exp.Qualify, "this")
        require(self.source == "databricks" and all(expr.find(exp.Window) is None for expr in projections),
                "qualify_scope")
        predicate = node.this
        require(type(predicate) in (exp.EQ, exp.LTE), "qualify_predicate")
        shape(predicate, type(predicate), "this", "expression")
        shape(predicate.this, exp.Window, "this", "partition_by", "order", "over")
        limit = self.integer_literal(predicate.expression)
        require(limit > 0 and (type(predicate) is exp.LTE or limit == 1), "qualify_limit")
        rank, _, _ = self.ranking(predicate.this)
        helper = "_toolbelt_row_number"
        relation = quote("_toolbelt_qualified", self.target)
        rank_name = quote(helper, self.target)
        require(helper.casefold() not in {column["name"].casefold() for column in schema}, "qualify_alias")
        names = [quote(column["name"], self.target) for column in schema]
        public = ", ".join(f"{relation}.{name} AS {name}" for name in names)
        inner = f"SELECT {', '.join(outputs)}, {rank} AS {rank_name}{source_sql}"
        operator = "<=" if type(predicate) is exp.LTE else "="
        return public, f"\nFROM (\n{inner}\n) AS {relation}\nWHERE {relation}.{rank_name} {operator} {limit}"

    def count(self, node):
        shape(node, exp.Count, "this", "big_int")
        if type(node.this) is exp.Star:
            shape(node.this, exp.Star)
            operand = "*"
        else:
            shape(node.this, exp.Column, "this", "table")
            operand, _, _ = self.operand(node.this)
        expression = ("COUNT_BIG" if self.target == "tsql" else "COUNT") + f"({operand})"
        if self.source == "tsql" and node.args.get("big_int") is False:
            self.count32_bound()
            return f"CAST({expression} AS INT)", "INT", False
        return expression, "BIGINT", False

    def count32_bound(self):
        bound = self.context.get("max_group_rows")
        require(type(bound) is int and 0 <= bound <= 2_147_483_647, "count32_cardinality", "requires_context")
        fact = {"max_group_rows": bound}
        if fact not in self.assumptions:
            self.assumptions.append(fact)

    @staticmethod
    def order_key(node):
        shape(node, exp.Ordered, "this", "desc", "nulls_first")
        shape(node.this, exp.Column, "this")
        return identifier(node.this.this)

    def ordering(self, node, schema):
        shape(node, exp.Order, "expressions")
        columns = {column["name"]: column for column in schema}
        order = []
        seen = set()
        for item in node.expressions:
            name = self.order_key(item)
            require(name in columns and name not in seen and not columns[name]["nullable"], "order_key")
            seen.add(name)
            order.append(quote(name, self.target) + (" DESC" if item.args.get("desc") else " ASC"))
        require(bool(order), "order_key")
        return ", ".join(order)

    def row_limit(self, limit, order):
        shape(limit, exp.Limit, "expression")
        shape(limit.expression, exp.Literal, "this", "is_string")
        text = limit.expression.this
        require(not limit.expression.is_string and re.fullmatch(r"[0-9]{1,10}", text)
                and 1 <= int(text) <= 2_147_483_647, "limit_literal")
        require(order is not None, "limit_order", "requires_context")
        keys = [self.order_key(node) for node in order.expressions]
        require(self.context.get("unique_order") == keys, "limit_order_unique", "requires_context")
        self.assumptions.append({"unique_order": keys})
        return int(text)


def convert(query, source, context):
    result = {"format_version": 1, "profile": "integer-select", "sql": None, "native_validation": "not executed"}
    try:
        require(sqlglot.__version__ == PIN, "provider_version", "invalid_input")
        require(source in ("tsql", "databricks") and isinstance(context, dict), "input_contract", "invalid_input")
        require(len(query.encode("utf-8")) <= MAX_SQL_BYTES, "sql_bytes", "limit_exceeded")
        dialect = Dialect.get_or_raise(source)
        tokens = dialect.tokenize(query)
        require(len(tokens) <= MAX_TOKENS, "tokens", "limit_exceeded")
        depth = 0
        for token in tokens:
            require(not token.comments, "comments")
            depth += (token.token_type.name == "L_PAREN") - (token.token_type.name == "R_PAREN")
            require(depth <= MAX_DEPTH, "parentheses", "limit_exceeded")
        parser = dialect.parser(error_level=ErrorLevel.RAISE)
        # SQLGlot's command fallback normally logs an excerpt of input SQL.
        # Replace the diagnostic on this parser instance before parsing.
        def reject_command():
            raise Rejected("unsupported", "provider_command")

        parser._warn_unsupported = reject_command
        trees = parser.parse(tokens, sql=query)
        require(len(trees) == 1 and trees[0] is not None, "statement_count", "invalid_input")
        binding = SelectBinding(source, context)
        sql, schema = binding.query(trees[0])
        sql += ";"
        reparsed = sqlglot.parse(sql, read=binding.target, error_level=ErrorLevel.RAISE)
        require(len(reparsed) == 1 and type(reparsed[0]) in (exp.Select, exp.Union), "target_syntax")
        return dict(result, status="converted", sql=sql, result_schema=schema, parameters=binding.parameters,
                    required_capabilities=sorted(binding.capabilities), assumptions=binding.assumptions)
    except Rejected as error:
        return dict(result, status=error.status, code=error.code)
    except (ParseError, TokenError, UnicodeError):
        return dict(result, status="invalid_input", code="syntax")
    except RecursionError:
        return dict(result, status="limit_exceeded", code="parser_depth")


def read_text(path, limit):
    with path.open("rb") as stream:
        data = stream.read(limit + 1)
    require(len(data) <= limit, "file_bytes", "limit_exceeded")
    return data.decode("utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, choices=("tsql", "databricks"))
    parser.add_argument("--sql", type=Path, required=True)
    parser.add_argument("--context", type=Path)
    args = parser.parse_args()
    try:
        context = json.loads(read_text(args.context, MAX_CONTEXT_BYTES)) if args.context else {}
        result = convert(read_text(args.sql, MAX_SQL_BYTES), args.source, context)
    except Rejected as error:
        result = {"format_version": 1, "status": error.status, "code": error.code, "sql": None}
    except (OSError, UnicodeError, json.JSONDecodeError):
        result = {"format_version": 1, "status": "invalid_input", "code": "input_file", "sql": None}
    print(json.dumps(result, ensure_ascii=True))
    return 0 if result["status"] == "converted" else 1


if __name__ == "__main__":
    raise SystemExit(main())
