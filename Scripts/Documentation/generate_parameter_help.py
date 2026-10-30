"""Generate public USP help from the same parameter notes as the API reference.

Only the existing help branch is replaced. No runtime lookup, new SQL object,
installation dependency or file access is introduced. SSIS has its own coupled
T-SQL/CLR generator and consumes the same notes through parameter_notes().
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Tests/Documentation"))
import generate_api_catalog as catalog

METADATA = "Documentation/Reference/usp_help.json"
BEGIN = "-- API_PARAMETER_HELP:BEGIN"
END = "-- API_PARAMETER_HELP:END"
INTERNAL_LOB_NOTE = "Interner CLR-Einstieg: kein technischer SQL-Default; auch für Hilfe explizit übergeben. Der folgende fachliche Eingabevertrag beschreibt die öffentliche Fassade. "
INTERNAL_UNICODE_NOTE = "Interner CLR-Einstieg: Unicodebindung als nvarchar statt varchar; fachlich gilt der folgende Eingabevertrag der öffentlichen Fassade. "
# Comments and quoted tokens are consumed as units. BEGIN/END inside a text,
# quoted identifier or CASE expression cannot terminate the enclosing branch.
TOKEN = re.compile(r"--[^\n]*|/\*(?:[^*]|\*(?!/))*\*/|N?'(?:[^']|'')*'|\[(?:[^\]]|\]\])*\]|@@?\w+|\w+|[^\s]", re.I)


def tokens(text):
    return [m for m in TOKEN.finditer(text) if not m[0].startswith(("--", "/*"))]


def help_span(text, item):
    ts = tokens(text)
    starts = [i for i, t in enumerate(ts) if t[0].upper() == "CREATE"
              and any(x[0].strip("[]") == item["name"] for x in ts[i:i+12])]
    if len(starts) != 1:
        raise ValueError("Ambiguous procedure declaration: " + item["name"])
    for i in range(starts[0], len(ts)):
        if ts[i][0].upper() != "IF":
            continue
        j = i + 1
        while j < len(ts) and ts[j][0].upper() != "BEGIN":
            j += 1
        if not any(t[0].lower() == "@hilfe" for t in ts[i:j]):
            continue
        level, k = 1, j + 1
        while level and k < len(ts):
            word = ts[k][0].upper()
            if word in ("BEGIN", "CASE"):
                level += 1
            elif word == "END":
                level -= 1
            k += 1
        if level:
            raise ValueError("Unclosed help branch: " + item["name"])
        return ts[j].end(), ts[k-1].start()
    raise ValueError("Missing help branch: " + item["name"])


def parameter_notes(root=ROOT):
    return json.loads((Path(root) / "Documentation/Reference/api_examples.json").read_text(encoding="utf-8"))


def literal(value, large=False):
    if value is None:
        return "NULL"
    if isinstance(value, (bool, int)):
        return str(int(value))
    if not isinstance(value, str):
        raise ValueError("Unsupported help value")
    # A MAX operand from the first chunk prevents intermediate 4000-code-unit
    # truncation, including supplementary Unicode and doubled SQL apostrophes.
    chunks, chunk, units = [], "", 0
    for char in value:
        width = len(char.encode("utf-16-le")) // 2
        if units + width > 2000:
            chunks.append(chunk)
            chunk, units = "", 0
        chunk += char
        units += width
    chunks.append(chunk)
    strings = ["N'" + c.replace("'", "''") + "'" for c in chunks]
    if large or len(strings) > 1:
        strings[0] = "CAST(" + strings[0] + " AS nvarchar(max))"
    return " + ".join(strings)


def default_value(param):
    default = param["default"]
    if default == "kein Default":
        return None
    # Preserve the actual SQL spelling, distinguishing absent default from the
    # explicit technical NULL default. No undocumented effective default is used.
    return default


def help_rows(item, params, metadata, registry):
    key = item["schema"] + "." + item["name"]
    if set(metadata) != {"parameters", "rows"}:
        raise ValueError("Invalid help metadata: " + key)
    flags, notes = metadata["parameters"], registry[key]["parameter_notes"]
    names = {p["name"] for p in params}
    if set(flags) != names or set(notes) != names:
        raise ValueError("Help parameters differ from SQL signature: " + key)
    rows = list(metadata["rows"])
    if any(len(r) != 9 or r[0] == "PARAMETER" for r in rows):
        raise ValueError("Parameter descriptions must come from api_examples.json: " + key)
    for i, p in enumerate(params, 1):
        bits = flags[p["name"]]
        if len(bits) != 2 or any(type(b) is not bool for b in bits):
            raise ValueError("Expected required/nullable booleans: " + key)
        rows.append(["PARAMETER", i, p["name"], p["type"], *bits,
                     default_value(p), notes[p["name"]], None])
    sections = {r[0] for r in rows}
    if not {"DESCRIPTION", "PARAMETER", "RESULT_COLUMN", "EXAMPLE"} <= sections:
        raise ValueError("Missing mandatory help section: " + key)
    if any(not isinstance(r[7], str) or not r[7] for r in rows):
        raise ValueError("Empty help description: " + key)
    return rows


def render(item, rows):
    values = ",\n".join("        (" + ", ".join(literal(v, i in (7, 8)) for i, v in enumerate(row)) + ")" for row in rows)
    return "\n        " + BEGIN + "\n" + """        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(""" + literal(item["schema"]) + """ AS sysname) AS SchemaName,
            CAST(""" + literal(item["name"]) + """ AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
""" + values + """
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        """ + END + "\n    "


def generate(root=ROOT, write=False):
    root = Path(root)
    metadata = json.loads((root / METADATA).read_text(encoding="utf-8"))
    registry = parameter_notes(root)
    expected, changes = set(), {}
    for item in catalog.objects(root):
        if item["type"] != "USP" or item["module"] == "toolbelt.tsql.ssis-debug":
            continue
        key = item["schema"] + "." + item["name"]
        expected.add(key)
        path, params = catalog.signature(item)
        text = changes.get(path, path.read_text(encoding="utf-8-sig"))
        a, b = help_span(text, item)
        body = render(item, help_rows(item, params, metadata[key], registry))
        if not write and text[a:b] != body:
            raise ValueError("Generated parameter help is stale: " + key)
        changes[path] = text[:a] + body + text[b:]
    if set(metadata) != expected:
        raise ValueError("Help registry differs from public USP manifest")
    if write:
        for path, text in changes.items():
            path.write_text(text, encoding="utf-8", newline="\n")
    return len(expected)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    print(f"Parameter help: {generate(write=args.write)} procedures; SSIS checked by its module generator.")
