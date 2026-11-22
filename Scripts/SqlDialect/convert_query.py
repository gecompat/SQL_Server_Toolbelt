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
        self.alias = None
        self.columns = {}
        self.parameters = {}

    def relation(self, node):
        shape(node, exp.From, "this")
        table = node.this
        shape(table, exp.Table, "this", "db", "catalog", "alias")
        parts = tuple(identifier(table.args[key]) for key in ("catalog", "db", "this") if table.args.get(key))
        source_width = 2 if self.source == "tsql" else 3
        require(len(parts) == source_width, "qualified_relation", "requires_context")
        table_alias = table.args.get("alias")
        shape(table_alias, exp.TableAlias, "this")
        self.alias = identifier(table_alias.this)
        binding = self.context.get("relation")
        require(isinstance(binding, dict) and binding.get("source") == list(parts),
                "relation_mapping", "requires_context")
        target = binding.get("target")
        require(isinstance(target, list) and len(target) == 5 - source_width
                and all(isinstance(part, str) and NAME.fullmatch(part) for part in target),
                "target_relation", "requires_context")
        columns = binding.get("columns")
        require(isinstance(columns, dict) and bool(columns), "relation_columns", "requires_context")
        self.columns = columns
        return ".".join(quote(part, self.target) for part in target) + " AS " + quote(self.alias, self.target)

    def operand(self, node):
        if type(node) is exp.Column:
            shape(node, exp.Column, "this", "table")
            require(self.alias is not None and node.args.get("table") is not None
                    and identifier(node.args["table"]) == self.alias, "column_qualifier", "requires_context")
            name = identifier(node.this)
            sql_type, nullable = self.column_contract(self.columns.get(name))
            return f"{quote(self.alias, self.target)}.{quote(name, self.target)}", sql_type, nullable
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

    def select(self, tree):
        shape(tree, exp.Select, "expressions", "from_", "where")
        relation = self.relation(tree.args["from_"]) if tree.args.get("from_") else None
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
        sql = "SELECT " + ", ".join(outputs)
        if relation:
            sql += "\nFROM " + relation
        where = tree.args.get("where")
        if where:
            shape(where, exp.Where, "this")
            sql += "\nWHERE " + self.predicate(where.this)
        require(len(self.parameters) <= 64 and len({name.casefold() for name in self.parameters}) == len(self.parameters),
                "parameter_inventory")
        return sql + ";", schema


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
        reparsed = sqlglot.parse(sql, read=binding.target, error_level=ErrorLevel.RAISE)
        require(len(reparsed) == 1 and type(reparsed[0]) is exp.Select, "target_syntax")
        return dict(result, status="converted", sql=sql, result_schema=schema, parameters=binding.parameters)
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
