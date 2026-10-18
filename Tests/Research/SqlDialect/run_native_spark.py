"""Führt denselben festen SQL-Korpus nativ auf lokalem Apache Spark aus.

Dies ist ein eigener Engine-Nachweis, keine native Databricks-Abnahme.
Parameter werden über SparkSession.sql(args=...) gebunden, nicht interpoliert.
"""

from __future__ import annotations

import argparse
from datetime import date, datetime, timezone
from decimal import Decimal
import json
import logging
import os
from pathlib import Path
import sys
from threading import Timer

from prepare_local_spark import ASSETS, RUNTIME, SPARK_VERSION
from run_native_databricks import (ProbeError, build, build_databricks, digest, load_baseline,
                                   rows_key, runtime_path, type_key)


def load_runtime() -> None:
    for name, _, wanted in ASSETS:
        if digest(RUNTIME / name) != wanted:
            raise ProbeError("ARTIFACT_HASH_MISMATCH")
    # Ausschließlich die festgelegte lokale Runtime, keine geerbte Remote-
    # oder Submitkonfiguration und keine globalen Umgebungsänderungen.
    spark = RUNTIME / "distribution/pyspark-4.0.2"
    java = RUNTIME / "java/jdk-21.0.12.1+1-jre"
    for key in ("SPARK_REMOTE", "SPARK_CONNECT_MODE_ENABLED", "SPARK_SUBMIT_OPTS", "SPARK_EXTRA_CLASSPATH",
                "JAVA_TOOL_OPTIONS", "_JAVA_OPTIONS", "CLASSPATH", "YARN_CONF_DIR", "HADOOP_HOME"):
        os.environ.pop(key, None)
    conf = RUNTIME / "empty-conf"
    conf.mkdir(exist_ok=True)
    os.environ.update(SPARK_HOME=str(spark / "deps"), JAVA_HOME=str(java), SPARK_LOCAL_IP="127.0.0.1",
                      SPARK_CONF_DIR=str(conf), HADOOP_CONF_DIR=str(conf), PYSPARK_SUBMIT_ARGS="pyspark-shell")
    sys.path[:0] = [str(spark), str(RUNTIME / ASSETS[1][0])]


def render(value):
    if value is None:
        return None
    if isinstance(value, datetime):
        return value.isoformat(timespec="microseconds")
    if isinstance(value, date):
        return value.isoformat()
    if isinstance(value, (int, Decimal, str)) and not isinstance(value, bool):
        return str(value)
    raise ProbeError("UNEXPECTED_CLIENT_VALUE")


def compare(case: dict, frame, values: list) -> dict:
    fields = frame.schema.fields
    if len(fields) != len(case["columns"]):
        raise ProbeError("COLUMN_COUNT")
    columns = []
    for index, (field, wanted) in enumerate(zip(fields, case["columns"])):
        dtype = field.dataType.simpleString()
        if field.name != wanted["name"] or type_key(dtype) != type_key(wanted["type"]):
            raise ProbeError("COLUMN_TYPE_OR_NAME")
        if any(row[index] is None for row in values) and not field.nullable:
            raise ProbeError("NULLABILITY_CONTRADICTION")
        columns.append(dict(name=field.name, sql_type=dtype, nullable=field.nullable,
                            python_types=sorted({type(row[index]).__name__ for row in values if row[index] is not None})))
    rows = [[render(value) for value in row] for row in values]
    if rows_key(rows, case["columns"], case["ordered"]) != rows_key(
            case["expected_rows"], case["columns"], case["ordered"]):
        raise ProbeError("RESULT_BAG_OR_ORDER")
    return dict(rows=rows, columns=columns)


def negative_cases() -> list[tuple[str, str, str]]:
    # Erwartete Fehlerkategorien statt beliebiger Exceptions als Positivbeweis.
    return [
        ("tsql-top-syntax", "SELECT TOP (1) 1 AS v", "PARSE_SYNTAX_ERROR"),
        ("limit-percent", "SELECT 1 AS v LIMIT 10 PERCENT", "PARSE_SYNTAX_ERROR"),
        ("limit-with-ties", "SELECT 1 AS v LIMIT 1 WITH TIES", "PARSE_SYNTAX_ERROR"),
        ("tinyint-positive-overflow", "SELECT CAST(128 AS TINYINT) AS v", "CAST_OVERFLOW"),
        ("tinyint-negative-overflow", "SELECT CAST(-129 AS TINYINT) AS v", "CAST_OVERFLOW"),
        ("int-overflow", "SELECT CAST(2147483648 AS INT) AS v", "CAST_OVERFLOW"),
        ("decimal-overflow", "SELECT CAST(1000 AS DECIMAL(3,0)) AS v", "NUMERIC_VALUE_OUT_OF_RANGE"),
        ("invalid-date", "SELECT CAST('2026-02-30' AS DATE) AS v", "CAST_INVALID_INPUT"),
        ("unbound-parameter", "SELECT :Missing AS v", "UNBOUND_SQL_PARAMETER"),
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--sql-server-report", type=Path, required=True)
    args = parser.parse_args()
    output = runtime_path(args.output)
    native = build()
    probes = build_databricks(native)
    baseline_path = runtime_path(args.sql_server_report)
    baseline_hash = digest(baseline_path)
    baseline = load_baseline(baseline_path, native, probes)
    if digest(baseline_path) != baseline_hash:
        raise ProbeError("SQL_SERVER_BASELINE_DRIFT")
    own = Path(__file__).parent
    source_hashes = dict(native["source_hashes"], **{name: digest(own / name) for name in
        ("run_native_spark.py", "prepare_local_spark.py", "run_native_databricks.py")})
    report = dict(generated_at=datetime.now(timezone.utc).isoformat(), engine="Apache Spark",
                  expected_version=SPARK_VERSION, source_hashes=source_hashes,
                  sql_server_baseline_sha256=baseline_hash, sql_server_reexecuted=False,
                  databricks_execution="not executed", performance="not executed",
                  status="not executed", cases=[], negative_cases=[])
    spark = None
    exit_code = 2
    try:
        load_runtime()
        import pyspark
        from pyspark.sql import SparkSession
        from pyspark.errors import PySparkException
        if pyspark.__version__ != SPARK_VERSION:
            raise ProbeError("SPARK_VERSION_MISMATCH")
        work = RUNTIME / "work"
        work.mkdir(exist_ok=True)
        # Kein Hive, UI oder Eventlog; Treiber und lokale Tasks nur auf Loopback.
        spark = (SparkSession.builder.master("local[2]").appName("SyntheticSqlDialectProbe")
                 .config("spark.ui.enabled", "false").config("spark.eventLog.enabled", "false")
                 .config("spark.driver.host", "127.0.0.1").config("spark.driver.bindAddress", "127.0.0.1")
                 .config("spark.local.dir", str(work)).config("spark.sql.warehouse.dir", (work / "warehouse").as_uri())
                 .config("spark.sql.ansi.enabled", "true").config("spark.sql.session.timeZone", "UTC")
                 .config("spark.sql.timestampType", "TIMESTAMP_NTZ").config("spark.sql.caseSensitive", "true")
                 .config("spark.sql.shuffle.partitions", "2").getOrCreate())
        spark.sparkContext.setLogLevel("ERROR")
        for name in ("SQLQueryContextLogger", "DataFrameQueryContextLogger"):
            logging.getLogger(name).disabled = True
        if spark.version != SPARK_VERSION:
            raise ProbeError("SPARK_VERSION_MISMATCH")
        report.update(spark_version=spark.version, java_version=spark.sparkContext._jvm.java.lang.System.getProperty("java.version"),
                      python_version=sys.version.split()[0], session=dict(ansi=True, timezone="UTC", timestamp_type="TIMESTAMP_NTZ", case_sensitive=True))
        exit_code = 0
        first_target = {c["name"]: c for c in baseline["targets"][0]["cases"]}
        for case in probes:
            entry = dict(name=case["name"], status="failed", sql_server_cases=case["sql_server_cases"])
            spark.sparkContext.setJobGroup(case["name"], "Fixed synthetic SQL", interruptOnCancel=True)
            timer = Timer(30, spark.sparkContext.cancelJobGroup, args=(case["name"],))
            timer.daemon = True
            timer.start()
            try:
                # Das API akzeptiert Literalwerte, keine Castausdrücke. Integer
                # werden hier auf die deklarierte INT-Domäne begrenzt. None wird
                # vom API als untypisiertes NULL gebunden; dies bleibt eine eigene
                # Grenze gegenüber explizit typisiertem REST-/SQLClient-Binding.
                bindings = {p["name"]: None if p["value"] is None else int(p["value"]) for p in case["parameters"]}
                if any(v is not None and not -(2**31) <= v < 2**31 for v in bindings.values()):
                    raise ProbeError("PARAMETER_OUTSIDE_INT_DOMAIN")
                entry["parameter_bindings"] = [dict(name=n, python_type=type(v).__name__,
                    api_type="untyped NULL" if v is None else "INT") for n, v in bindings.items()]
                frame = spark.sql(case["sql"], args=bindings)
                values = frame.collect()
                entry["result"] = compare(case, frame, values)
                entry["sql_server_metadata"] = {alias: first_target[alias]["result"]["columns"] for alias in case["sql_server_cases"]}
                entry.update(status="validated", sql_server_value_parity="validated against six-target baseline")
            except ProbeError as error:
                entry["code"] = str(error)
                exit_code = 1
            except PySparkException as error:
                entry["condition"] = error.getCondition()
                entry["sql_state"] = error.getSqlState()
                exit_code = 1
            finally:
                timer.cancel()
                spark.sparkContext.setLocalProperty("spark.jobGroup.id", None)
            report["cases"].append(entry)
            print(json.dumps(dict(name=entry["name"], status=entry["status"], code=entry.get("code"), condition=entry.get("condition"))), flush=True)
        for name, query, wanted in negative_cases():
            entry = dict(name=name, expected_condition=wanted, status="failed")
            try:
                spark.sql(query).collect()
                entry["code"] = "EXPECTED_REJECTION_MISSING"
                exit_code = 1
            except PySparkException as error:
                condition = error.getCondition() or ""
                entry.update(condition=condition, sql_state=error.getSqlState())
                if condition == wanted or condition.startswith(wanted + "."):
                    entry["status"] = "validated"
                else:
                    exit_code = 1
            report["negative_cases"].append(entry)
        if digest(baseline_path) != baseline_hash:
            raise ProbeError("SQL_SERVER_BASELINE_DRIFT")
    except Exception as error:
        report["code"] = str(error) if isinstance(error, ProbeError) else "LOCAL_OR_SPARK_FAILURE"
        exit_code = 1 if spark is not None else 2
    finally:
        if spark is not None:
            spark.stop()
    for name, wanted in source_hashes.items():
        if digest(own / name) != wanted:
            report["code"] = "SOURCE_DRIFT"
            exit_code = 1
    report["status"] = "validated" if exit_code == 0 else "failed" if exit_code == 1 else "not executed"
    report["summary"] = dict(positive_passed=sum(c["status"] == "validated" for c in report["cases"]),
                             positive_total=len(report["cases"]),
                             negative_passed=sum(c["status"] == "validated" for c in report["negative_cases"]),
                             negative_total=len(report["negative_cases"]))
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(dict(status=report["status"], **report["summary"])))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
