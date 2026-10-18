"""Begrenzter nativer Databricks-Vergleich mit dem bestehenden SQL-Lab-Korpus.

Nur feste synthetische SELECTs, keine Tabellen oder Warehouse-Konfigurationen.
REST-Zugang ausschließlich über lokale Umgebungsvariablen; keine Secrets im
Bericht. Ohne Zugang bleibt die native Ausführung ausdrücklich not executed.
"""

from __future__ import annotations

import argparse
from collections import Counter
from datetime import date, datetime, timezone
from decimal import Decimal
import hashlib
import json
import os
from pathlib import Path
import re
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener

import sqlglot

from build_native_cases import build, cte, relations
from rules_probe import rewrite
from run_rule_spike import cases, result_cast_cases
from run_spike import PIN, ROOT


class ProbeError(Exception):
    """Enthält ausschließlich einen eigenen, veröffentlichbaren Fehlercode."""


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def runtime_path(path: Path) -> Path:
    path = path.resolve()
    if not path.is_relative_to(ROOT / ".runtime"):
        raise ProbeError("REPORT_OUTSIDE_RUNTIME")
    return path


def type_key(text: str) -> str:
    # Typaliase normalisieren; insbesondere DECIMAL-Dimensionen nicht verwerfen.
    return sqlglot.exp.DataType.build(text, dialect="databricks").sql(dialect="databricks")


def canonical(value: object, dtype: str) -> str | None:
    if value is None:
        return None
    if not isinstance(value, str):
        raise ProbeError("NON_STRING_API_VALUE")
    if dtype in ("TINYINT", "SMALLINT", "INT", "BIGINT"):
        if not re.fullmatch(r"-?\d+", value):
            raise ProbeError("INVALID_INTEGER_RESULT")
        return str(int(value))
    if dtype.startswith("DECIMAL"):
        number = Decimal(value)
        if not number.is_finite():
            raise ProbeError("INVALID_DECIMAL_RESULT")
        return str(number.normalize())
    if dtype == "DATE":
        return date.fromisoformat(value).isoformat()
    if dtype == "TIMESTAMP_NTZ":
        # SQLClient liefert sieben Nachkommastellen. Nur eine zusätzliche Null
        # darf beim Vergleich mit der Mikrosekundenrepräsentation entfallen.
        match = re.fullmatch(r"(\d{4}-\d\d-\d\d)[T ](\d\d:\d\d:\d\d)(?:\.(\d{1,7}))?", value)
        if not match or (len(match[3] or "") == 7 and match[3][-1] != "0"):
            raise ProbeError("INVALID_NTZ_RESULT")
        fraction = (match[3] or "")[:6].ljust(6, "0")
        return datetime.fromisoformat(f"{match[1]}T{match[2]}.{fraction}").isoformat(timespec="microseconds")
    return value


def rows_key(rows: list, columns: list, ordered: bool):
    output = []
    for row in rows:
        if len(row) != len(columns):
            raise ProbeError("ROW_WIDTH")
        output.append(tuple(canonical(v, c["type"]) for v, c in zip(row, columns)))
    return output if ordered else Counter(output)


def build_databricks(native: dict) -> list[dict]:
    fixtures = cases() + [c for c in result_cast_cases() if c.name.startswith("count-null-column/")]
    lookup = {c.name: c for c in fixtures if c.rejection is None}
    result = []
    for item in native["cases"]:
        if item["direction"] == "roundtrip":
            continue  # Dasselbe Databricks-Zwischenstatement nur einmal ausführen.
        name = item["name"].split("/")[0]
        source = "databricks" if item["direction"] == "reverse" else "tsql"
        case = lookup[f"{name}/{source}"]
        query = case.query if source == "databricks" else rewrite(case.query, source, case.context)["sql"]
        parents, events = relations(item["profile"])
        used = {t.name for t in sqlglot.parse_one(query, read="databricks").find_all(sqlglot.exp.Table)}
        definitions = []
        if "Parent" in used:
            definitions.append(cte("Parent", ["ParentId", "CutoffTime"], ["INT", "TIMESTAMP_NTZ"], parents))
        if "Event" in used:
            definitions.append(cte("Event", ["EventId", "ParentId", "EventTime"], ["INT", "INT", "TIMESTAMP_NTZ"], events))
        sql = ("WITH " + ",".join(definitions) + "\n" if definitions else "") + query
        parsed = sqlglot.parse(sql, read="databricks", error_level=sqlglot.ErrorLevel.RAISE)
        assert len(parsed) == 1 and isinstance(parsed[0], sqlglot.exp.Select)
        columns = []
        for column in item["columns"]:
            dtype = column["sql_type"].upper()
            dtype = {"VARCHAR": "STRING", "DATETIME2": "TIMESTAMP_NTZ", "TINYINT": "SMALLINT"}.get(dtype, dtype)
            if name == "tinyint-edges" and source == "databricks":
                dtype = "TINYINT"  # Signierter Quelltyp; T-SQL-Ziel ist SMALLINT.
            if dtype == "DECIMAL":
                dtype = f"DECIMAL({column['precision']},{column['scale']})"
            columns.append(dict(name=column["name"], type=dtype))
        aliases = [item["name"]]
        if item["direction"] == "original":
            aliases.append(item["name"].replace("/original/", "/roundtrip/"))
        result.append(dict(name=item["name"], source=source, sql=sql,
                           parameters=[dict(name=p["name"], type="INT", value=None if p["value"] is None else str(p["value"]))
                                       for p in item["parameters"]],
                           columns=columns, expected_rows=item["expected_rows"], ordered=item["ordered"],
                           sql_server_cases=aliases))
    assert len(result) == 57 and sum(len(c["sql_server_cases"]) for c in result) == 81
    return result


def load_baseline(path: Path, native: dict, probes: list) -> dict:
    baseline = json.loads(runtime_path(path).read_text(encoding="utf-8-sig"))
    if (baseline.get("source_hashes") != native["source_hashes"] or baseline.get("source_drift") or
            baseline.get("sqlglot_version") != PIN or baseline.get("cases_per_target") != 81 or
            baseline.get("lab_helper_hash", "").lower() != digest(ROOT / "Tests/CI/run-lab-local.ps1").lower()):
        raise ProbeError("SQL_SERVER_BASELINE_BINDING")
    targets = baseline.get("targets", [])
    if len(targets) != 6 or {(t["platform"], t["version"]) for t in targets} != {
            (p, v) for p in ("windows", "linux") for v in ("2019", "2022", "2025")}:
        raise ProbeError("SQL_SERVER_BASELINE_TARGETS")
    expected = {c["name"]: c for c in native["cases"]}
    for target in targets:
        actual = {c["name"]: c for c in target["cases"]}
        if target["status"] != "validated" or len(target["cases"]) != 81 or set(actual) != set(expected):
            raise ProbeError("SQL_SERVER_BASELINE_INCOMPLETE")
        for probe in probes:
            for alias in probe["sql_server_cases"]:
                entry, contract = actual[alias], expected[alias]
                if entry["status"] != "validated":
                    raise ProbeError("SQL_SERVER_BASELINE_FAILED")
                result = entry["result"]
                if len(result["columns"]) != len(contract["columns"]):
                    raise ProbeError("SQL_SERVER_BASELINE_COLUMNS")
                for col, wanted in zip(result["columns"], contract["columns"]):
                    if any(col.get(k) != v for k, v in wanted.items()):
                        raise ProbeError("SQL_SERVER_BASELINE_TYPES")
                if rows_key(result["rows"], probe["columns"], probe["ordered"]) != rows_key(
                        probe["expected_rows"], probe["columns"], probe["ordered"]):
                    raise ProbeError("SQL_SERVER_BASELINE_VALUES")
    return baseline


def compare_response(case: dict, response: dict) -> dict:
    if response.get("status", {}).get("state") != "SUCCEEDED":
        raise ProbeError("SQL_NOT_SUCCEEDED")
    manifest, result = response.get("manifest", {}), response.get("result", {})
    if manifest.get("truncated") or manifest.get("format") != "JSON_ARRAY":
        raise ProbeError("RESULT_TRUNCATED_OR_FORMAT")
    if (manifest.get("total_chunk_count", 0) > 1 or result.get("next_chunk_index") is not None or
            result.get("next_chunk_internal_link") or result.get("external_links")):
        raise ProbeError("UNEXPECTED_RESULT_CHUNKS")
    columns = manifest.get("schema", {}).get("columns", [])
    if len(columns) != len(case["columns"]):
        raise ProbeError("COLUMN_COUNT")
    for index, (col, wanted) in enumerate(zip(columns, case["columns"])):
        if col.get("position") != index or col.get("name") != wanted["name"] or type_key(col.get("type_text", "")) != type_key(wanted["type"]):
            raise ProbeError("COLUMN_TYPE_OR_NAME")
    rows = result.get("data_array", [])
    if manifest.get("total_row_count") != len(rows):
        raise ProbeError("ROW_COUNT")
    if rows_key(rows, case["columns"], case["ordered"]) != rows_key(case["expected_rows"], case["columns"], case["ordered"]):
        raise ProbeError("RESULT_BAG_OR_ORDER")
    return dict(rows=rows, columns=columns, metadata_nullability="not exposed by this API",
                client_representation="JSON strings / null")


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise ProbeError("HTTP_REDIRECT_REJECTED")


class Client:
    def __init__(self):
        keys = ("DATABRICKS_HOST", "DATABRICKS_TOKEN", "DATABRICKS_SQL_WAREHOUSE_ID")
        if any(not os.environ.get(k) for k in keys):
            raise ProbeError("DATABRICKS_CONFIG_MISSING")
        host = urlsplit(os.environ[keys[0]])
        if (host.scheme != "https" or not host.hostname or host.username or host.password or
                host.path not in ("", "/") or host.query or host.fragment or host.port not in (None, 443)):
            raise ProbeError("DATABRICKS_HOST_INVALID")
        self.host, self.token, self.warehouse = host.geturl().rstrip("/"), os.environ[keys[1]], os.environ[keys[2]]
        if not re.fullmatch(r"[a-zA-Z0-9-]{1,80}", self.warehouse):
            raise ProbeError("DATABRICKS_WAREHOUSE_INVALID")
        self.opener = build_opener(NoRedirect())  # Standard-TLS-Prüfung bleibt aktiv.

    def request(self, method: str, path: str, body: dict | None = None) -> dict:
        request = Request(self.host + path, data=None if body is None else json.dumps(body).encode(),
                          headers={"Authorization": "Bearer " + self.token, "Content-Type": "application/json"}, method=method)
        try:
            with self.opener.open(request, timeout=40) as response:
                data = response.read(2 * 1024 * 1024 + 1)
                if len(data) > 2 * 1024 * 1024:
                    raise ProbeError("HTTP_RESPONSE_TOO_LARGE")
                return json.loads(data)
        except HTTPError as error:
            raise ProbeError(f"HTTP_{error.code}") from None
        except (URLError, TimeoutError):
            raise ProbeError("HTTP_TRANSPORT_FAILURE") from None

    def execute(self, sql: str, parameters: list) -> dict:
        return self.request("POST", "/api/2.0/sql/statements", dict(
            warehouse_id=self.warehouse, statement=sql, parameters=parameters,
            format="JSON_ARRAY", disposition="INLINE", row_limit=100, byte_limit=1048576,
            wait_timeout="30s", on_wait_timeout="CANCEL"))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--sql-server-report", type=Path, required=True)
    parser.add_argument("--prepare-only", action="store_true")
    args = parser.parse_args()
    output = runtime_path(args.output)
    native = build()
    probes = build_databricks(native)
    source_hashes = dict(native["source_hashes"], **{Path(__file__).name: digest(Path(__file__))})
    report = dict(generated_at=datetime.now(timezone.utc).isoformat(), sqlglot_version=PIN,
                  source_hashes=source_hashes, databricks_execution="not executed", performance="not executed",
                  expected_cases=len(probes), cases=[], fixture_cases=probes)
    exit_code = 2
    try:
        baseline_path = runtime_path(args.sql_server_report)
        baseline_hash = digest(baseline_path)
        load_baseline(baseline_path, native, probes)
        if digest(baseline_path) != baseline_hash:
            raise ProbeError("SQL_SERVER_BASELINE_DRIFT")
        report["sql_server_baseline_sha256"] = baseline_hash
        report["sql_server_baseline"] = "81 cases on 6 targets rechecked locally; not reexecuted"
        if args.prepare_only:
            raise ProbeError("PREPARE_ONLY")
        client = Client()
        info = client.request("GET", "/api/2.0/sql/warehouses/" + client.warehouse)
        if info.get("state") != "RUNNING":
            raise ProbeError("WAREHOUSE_NOT_RUNNING")
        # Nur lokale Evidenz, keine Endpoints, Identitäten oder Inventarwerte.
        report["warehouse_channel"] = info.get("channel", {})
        preflight = client.execute("SELECT current_version() AS version, current_timezone() AS timezone", [])
        if preflight.get("status", {}).get("state") != "SUCCEEDED":
            raise ProbeError("DATABRICKS_PREFLIGHT_FAILED")
        report["preflight"] = preflight.get("result", {}).get("data_array", [])
        report["ansi_mode_qualification"] = "not executed"
        report["databricks_execution"] = "executed"
        exit_code = 0
        for case in probes:
            entry = dict(name=case["name"], status="failed")
            try:
                response = client.execute(case["sql"], case["parameters"])
                entry["result"] = compare_response(case, response)
                entry["status"] = "validated"
                entry["sql_server_value_parity"] = "validated against bound baseline"
            except ProbeError as error:
                entry["code"] = str(error)
                exit_code = 1
            report["cases"].append(entry)
            print(json.dumps(dict(name=entry["name"], status=entry["status"], code=entry.get("code"))), flush=True)
        if digest(baseline_path) != baseline_hash:
            raise ProbeError("SQL_SERVER_BASELINE_DRIFT")
    except ProbeError as error:
        report["code"] = str(error)
        if report["databricks_execution"] == "executed":
            exit_code = 1
    except Exception:
        report["code"] = "LOCAL_OR_CLIENT_FAILURE"  # Niemals ungefilterte Transport-/Dateifehler ausgeben.
        if report["databricks_execution"] == "executed":
            exit_code = 1
    for name, value in source_hashes.items():
        if digest(Path(__file__).parent / name) != value:
            report["code"] = "SOURCE_DRIFT"
            exit_code = 1
    report["status"] = "validated" if exit_code == 0 else "failed" if exit_code == 1 else "not executed"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(dict(status=report["status"], cases=len(report["cases"]), code=report.get("code"))))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
