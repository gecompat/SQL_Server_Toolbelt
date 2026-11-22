"""Translate the first explicitly bound, integer-only SELECT profile offline."""

import argparse
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
        self.ctes = {}
        self.parameters = {}
        self.capabilities = set()

    def relation(self, table):
        shape(table, exp.Table, "this", "db", "catalog", "alias")
        parts = tuple(identifier(table.args[key]) for key in ("catalog", "db", "this") if table.args.get(key))
        table_alias = table.args.get("alias")
        shape(table_alias, exp.TableAlias, "this")
        alias = identifier(table_alias.this)
        require(alias.casefold() not in {key.casefold() for key in self.relations}, "duplicate_relation_alias")
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
        return self.qualified(target, alias), alias

    def qualified(self, parts, alias):
        return ".".join(quote(part, self.target) for part in parts) + " AS " + quote(alias, self.target)

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
        require(alias.casefold() not in {key.casefold() for key in self.relations}, "duplicate_relation_alias")
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
        sql, schema = member.select(query, allow_ctes=False)
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
            sql, schema = self.child().select(entry.this, allow_ctes=False)
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
            operand, source_type, nullable = self.operand(node.this)
            require(target_type == source_type or (source_type, target_type) == ("INT", "BIGINT"), "integer_cast")
            return f"CAST({operand} AS {target_type})", target_type, nullable
        negative = type(node) is exp.Neg
        if negative:
            shape(node, exp.Neg, "this")
            node = node.this
        shape(node, exp.Literal, "this", "is_string")
        require(not node.is_string and re.fullmatch(r"[0-9]{1,10}", node.this), "integer_literal")
        value = int(node.this) * (-1 if negative else 1)
        # The minimum INT has dialect-specific literal typing. Keep a shared range.
        require(-2_147_483_647 <= value <= 2_147_483_647, "integer_literal_range")
        return f"CAST({value} AS INT)", "INT", False

    @staticmethod
    def column_contract(declaration):
        require(isinstance(declaration, dict), "operand_type", "requires_context")
        sql_type = declaration.get("type")
        nullable = declaration.get("nullable")
        require(sql_type in ("INT", "BIGINT") and type(nullable) is bool, "operand_contract", "requires_context")
        return sql_type, nullable

    def predicate(self, node):
        kind = type(node)
        if kind in (exp.And, exp.Or):
            shape(node, kind, "this", "expression")
            operator = "AND" if kind is exp.And else "OR"
            return f"({self.predicate(node.this)} {operator} {self.predicate(node.expression)})"
        if kind in (exp.Paren, exp.Not):
            shape(node, kind, "this")
            nested = self.predicate(node.this)
            return f"(NOT {nested})" if kind is exp.Not else f"({nested})"
        shape(node, kind, "this", "expression")
        require(kind in COMPARISONS or kind is exp.Is, "predicate")
        left, left_type, _ = self.operand(node.this)
        if kind is exp.Is:
            shape(node.expression, exp.Null)
            return f"({left} IS NULL)"
        right, right_type, _ = self.operand(node.expression)
        require(left_type == right_type, "mixed_type_comparison")
        return f"({left} {COMPARISONS[kind]} {right})"

    def select(self, tree, allow_ctes=True):
        shape(tree, exp.Select, "expressions", "from_", "where", "joins", "with_")
        with_node = tree.args.get("with_")
        require(allow_ctes or with_node is None, "nested_cte")
        prefix = self.with_clause(with_node) if with_node is not None else ""
        from_node = tree.args.get("from_")
        joins = tree.args.get("joins", [])
        require(from_node is not None or not joins, "join_from_required")
        from_sql = []
        if from_node is not None:
            shape(from_node, exp.From, "this")
            relation, _ = self.relation(from_node.this)
            from_sql.append("FROM " + relation)
            from_sql.extend(self.join(node) for node in joins)
        outputs = []
        schema = []
        seen = set()
        for projection in tree.expressions:
            shape(projection, exp.Alias, "this", "alias")
            name = identifier(projection.args["alias"])
            require(name.casefold() not in seen, "duplicate_output")
            seen.add(name.casefold())
            value, sql_type, nullable = self.operand(projection.this)
            outputs.append(f"{value} AS {quote(name, self.target)}")
            schema.append({"name": name, "type": sql_type, "nullable": nullable})
        require(bool(outputs), "projection_required")
        sql = prefix + "SELECT " + ", ".join(outputs)
        if from_sql:
            sql += "\n" + "\n".join(from_sql)
        where = tree.args.get("where")
        if where:
            shape(where, exp.Where, "this")
            sql += "\nWHERE " + self.predicate(where.this)
        require(len(self.parameters) <= 64 and len({name.casefold() for name in self.parameters}) == len(self.parameters),
                "parameter_inventory")
        return sql, schema


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
        sql, schema = binding.select(trees[0])
        sql += ";"
        reparsed = sqlglot.parse(sql, read=binding.target, error_level=ErrorLevel.RAISE)
        require(len(reparsed) == 1 and type(reparsed[0]) is exp.Select, "target_syntax")
        return dict(result, status="converted", sql=sql, result_schema=schema, parameters=binding.parameters,
                    required_capabilities=sorted(binding.capabilities))
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
