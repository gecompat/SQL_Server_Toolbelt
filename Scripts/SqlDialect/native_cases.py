"""Fixed synthetic statements for native acceptance of the current converter."""

import argparse
from hashlib import sha256
import json
import os
from pathlib import Path
import sys

from convert_query import convert


TS_PREFIX = "WITH q AS (SELECT 1 AS k, 1 AS id UNION ALL SELECT 1 AS k, 2 AS id) "
DB_PREFIX = TS_PREFIX
RANKING = {"max_partition_rows": 2, "ranking_order": ["t.k", "t.id"]}


def statements():
    # These are independent expected rows, including duplicates, NULL and type
    # widths. Nothing in the native runner accepts a caller's query or catalog.
    yield ("left_anti", "tsql", TS_PREFIX +
           "SELECT t.id AS id, r.id AS other FROM q AS t LEFT JOIN q AS r ON r.id = t.id "
           "WHERE NOT EXISTS (SELECT 1 AS k FROM q AS x WHERE x.id = t.id AND x.id = 1) ORDER BY id",
           {}, [["2", "2"]], True)
    yield ("qualify", "databricks", DB_PREFIX +
           "SELECT t.id AS id FROM q AS t QUALIFY ROW_NUMBER() OVER(PARTITION BY t.k ORDER BY t.id DESC) = 1",
           RANKING, [["2"]], False)
    yield ("typed_limit", "tsql", TS_PREFIX + "SELECT TOP (1) t.id AS id FROM q AS t ORDER BY id DESC",
           {"unique_order": ["id"]}, [["2"]], True)
    yield ("calendar", "tsql",
           "SELECT DATEADD(day,1,CAST('20240228' AS DATE)) AS result, "
           "DATEDIFF(day,CAST('20240228' AS DATE),CAST('20240301' AS DATE)) AS delta",
           {}, [["2024-02-29", "2"]], False)
    yield ("numeric_widths", "tsql", TS_PREFIX +
           "SELECT COUNT(*) AS c, COUNT_BIG(t.id) AS cb, MIN(t.id) AS minimum FROM q AS t",
           {"max_group_rows": 2}, [["2", "2", "1"]], False)
    yield ("decimal_null", "tsql",
           "SELECT CAST(NULL AS INT) AS missing, CAST(-1.125 AS DECIMAL(12,3)) AS exact",
           {}, [[None, "-1.125"]], False)
    yield ("lateral_empty_preserves_left", "tsql", TS_PREFIX +
           "SELECT t.id AS id, r.value AS value FROM q AS t "
           "OUTER APPLY (SELECT x.id AS value FROM q AS x WHERE x.id = t.id AND x.id = 1) AS r ORDER BY id",
           {"lateral_select": True}, [["1", "1"], ["2", None]], True)
    yield ("lateral_scalar_empty_count", "tsql", TS_PREFIX +
           "SELECT t.id AS id, r.n AS n FROM q AS t CROSS APPLY "
           "(SELECT COUNT_BIG(x.id) AS n FROM q AS x WHERE x.id = t.id AND x.id = 1) AS r ORDER BY id",
           {"lateral_select": True, "lateral_scalar_aggregate": True}, [["1", "1"], ["2", "0"]], True)
    yield ("lateral_ordered_cutoff", "tsql", TS_PREFIX +
           "SELECT t.id AS id, r.value AS value FROM q AS t OUTER APPLY "
           "(SELECT TOP (1) x.id AS value FROM q AS x WHERE x.k = t.k AND x.id <= t.id ORDER BY value DESC) AS r "
           "ORDER BY id",
           {"lateral_select": True, "lateral_ordered_limit": True, "lateral_unique_order": ["value"],
            "lateral_cutoff": True}, [["1", "1"], ["2", "2"]], True)
    yield ("multiplicity", "databricks",
           "SELECT 1 AS id UNION ALL SELECT 1 AS id UNION ALL SELECT CAST(NULL AS INT) AS id",
           {}, [["1"], ["1"], [None]], False)


def cases():
    for name, source, sql, context, rows, ordered in statements():
        translated = convert(sql, source, context)
        if translated["status"] != "converted":
            raise ValueError(f"NATIVE_FIXTURE_CONVERSION {name} {translated.get('code')}")
        types = translated["result_schema"]
        assert all(len(row) == len(types) for row in rows), name
        yield {"name": name, "tsql": sql if source == "tsql" else translated["sql"],
               "databricks": sql if source == "databricks" else translated["sql"],
               "columns": types, "expected_rows": rows, "ordered": ordered,
               "assumptions": translated["assumptions"], "capabilities": translated["required_capabilities"]}


def prove_databricks(probes):
    # Use the previously tested TLS/redirect, wire-format and size checks.
    if not all(os.environ.get(key) for key in ("DATABRICKS_HOST", "DATABRICKS_TOKEN", "DATABRICKS_SQL_WAREHOUSE_ID")):
        print("DATABRICKS_CONFIG_MISSING native_cases=0", file=sys.stderr)
        return 2
    root = Path(__file__).resolve().parents[2]
    sys.path.append(str(root / "Tests/Research/SqlDialect"))
    from run_native_databricks import Client, ProbeError, compare_response

    try:
        client = Client()
        info = client.request("GET", "/api/2.0/sql/warehouses/" + client.warehouse)
        if info.get("state") != "RUNNING":
            raise ProbeError("WAREHOUSE_NOT_RUNNING")
        for probe in probes:
            response = client.execute(probe["databricks"], [])
            compare_response(probe, response)
            print(f"NATIVE_DATABRICKS_CASE_PASS {probe['name']}")
    except ProbeError as error:
        print(str(error), file=sys.stderr)
        return 1
    except Exception:
        print("DATABRICKS_NATIVE_CLIENT_FAILURE", file=sys.stderr)
        return 1
    print(f"NATIVE_DATABRICKS_PASS cases={len(probes)}")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--databricks", action="store_true", help="Use an explicitly configured running warehouse.")
    args = parser.parse_args()
    probes = list(cases())
    source = Path(__file__).with_name("convert_query.py")
    fingerprint = sha256(source.read_bytes()).hexdigest()
    if args.databricks:
        print(f"DATABRICKS_CONVERTER_SHA256 {fingerprint}")
        return prove_databricks(probes)
    print(json.dumps({"converter_sha256": fingerprint, "cases": probes}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
