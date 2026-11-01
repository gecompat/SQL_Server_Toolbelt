"""Prüft den nativen Linux-Exporthostnachweis ohne Host- oder SQL-Ausführung."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
MODULE = "Modules/toolbelt.tsql.ssis-debug/"
REPORT = MODULE + "Tests/Qualification/ExportHost.Linux.20261101.json"
RUNTIME_SHA512 = "634326028645f38731c8c4e71a68356e4ca0d6b6607139a234ab760687f742063edaf33a1f20dda615742d2dc8300ca2ff857619d51fbb38090383b71334af89"
PRODUCT_COMMIT = "61b2dcedf6ba88570bd3ad46871cccb71fc15c45"
MODES = ("model", "bundle", "iteration-bundle", "scope-bundle", "pipeline-bundle")
NAMES = tuple(f"format{version}:{mode}" for version in (6, 8) for mode in MODES) + (
    "unicode-path-private-literal", "unknown-format", "prohibited-dtd",
    "malformed-xml", "wrong-extension", "missing-file", "usage",
)
COUNTS = (12, 14, 14, 14, 15) * 2 + (13,) + (3,) * 6
EXITS = (0,) * 11 + (3, 3, 3, 3, 4, 2)
LIMITS = ["SQL CLR on Linux", "SSIS runtime execution or SDK parity",
          "Production capacity", "Administrative installer trust",
          "Hard host or transport interruption", "Windows client or SSMS authentication",
          "Publication"]


def require(condition, code):
    if not condition:
        raise ValueError("SSIS_LINUX_EXPORT_" + code)


def unique(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, "DUPLICATE_KEY")
        result[key] = value
    return result


def digest(value, length=64):
    return type(value) is str and re.fullmatch(r"[0-9a-f]{" + str(length) + r"}", value) is not None


def validate(root=ROOT, report=None, *, check_files=True):
    if report is None:
        report = json.loads((root / REPORT).read_text("utf-8"), object_pairs_hook=unique)
    require(type(report) is dict and set(report) == {"contract", "date", "runtime", "runs", "assertions", "separate_boundaries"}, "ROOT")
    require(report["contract"] == "ssis-linux-export-qualification/1" and report["date"] == "2026-11-01", "IDENTITY")
    runtime = report["runtime"]
    require(type(runtime) is dict and set(runtime) == {"version", "rid", "archive_url", "archive_sha512", "metadata_url", "installation"}, "RUNTIME")
    require(runtime["version"] == "10.0.14" and runtime["rid"] == "linux-x64" and
            runtime["archive_url"] == "https://builds.dotnet.microsoft.com/dotnet/Runtime/10.0.14/dotnet-runtime-10.0.14-linux-x64.tar.gz" and
            runtime["metadata_url"] == "https://builds.dotnet.microsoft.com/dotnet/release-metadata/10.0/releases.json" and
            runtime["archive_sha512"] == RUNTIME_SHA512 and runtime["installation"] == "private test directory; no global installation", "RUNTIME_PROVENANCE")
    require(type(report["assertions"]) is int and report["assertions"] == 338 and report["separate_boundaries"] == LIMITS, "SCOPE")
    runs = report["runs"]
    require(type(runs) is list and len(runs) == 2 and [r.get("platform") for r in runs] == ["Windows", "Linux"], "NATIVE_PLATFORMS")
    fixed = {MODULE + p for p in ("Exchange/Tests/qualify_host.py", "Exchange/Host/Program.cs",
             "Exchange/Host/Toolbelt.Ssis.Export.csproj", "Contracts/Exchange/Fixtures/direct-8.dtsx",
             "Contracts/Exchange/Fixtures/direct-8.expected.json")}
    required = fixed | {p.relative_to(root).as_posix() for p in (root / MODULE / "Exchange/Core").glob("*.cs")}
    keys = {"contract", "date", "platform", "result", "sql_executed", "host_sha256", "source_commit",
            "source_sha256", "case_count", "assertions", "cases"}
    for run in runs:
        require(type(run) is dict and set(run) == keys and run["contract"] == "ssis-export-host-native/1" and
                run["date"] == report["date"] and run["result"] == "PASS" and run["sql_executed"] is False, "NATIVE_RESULT")
        require(digest(run["host_sha256"]) and run["source_commit"] == PRODUCT_COMMIT, "ARTIFACT")
        require(type(run["case_count"]) is int and run["case_count"] == 17 and
                type(run["assertions"]) is int and run["assertions"] == 169, "COUNTS")
        cases = run["cases"]
        require(type(cases) is list and len(cases) == len(NAMES), "CASES")
        for case, name, count, code in zip(cases, NAMES, COUNTS, EXITS):
            require(type(case) is dict and set(case) == {"name", "exit_code", "assertions", "output_sha256"} and
                    case["name"] == name and type(case["exit_code"]) is int and case["exit_code"] == code and
                    type(case["assertions"]) is int and case["assertions"] == count and digest(case["output_sha256"]), "CASE_ORACLE")
            require(case["output_sha256"] == hashlib.sha256(b"").hexdigest() if code else
                    case["output_sha256"] != hashlib.sha256(b"").hexdigest(), "OUTPUT_BOUNDARY")
        pins = run["source_sha256"]
        require(type(pins) is dict and set(pins) == required and all(digest(v) for v in pins.values()), "SOURCE_CLOSURE")
        if check_files:
            for relative, expected in pins.items():
                path = root / relative
                require(path.is_file() and not path.is_symlink() and
                        hashlib.sha256(path.read_bytes()).hexdigest() == expected, "SOURCE_PIN")
    for key in ("source_sha256", "host_sha256", "source_commit", "cases"):
        require(runs[0][key] == runs[1][key], "CROSS_PLATFORM_EQUALITY")
    return report


if __name__ == "__main__":
    validate()
    print("SSIS_LINUX_EXPORT_EVIDENCE_PASS native Linux/Windows 17 cases each; 338 assertions; no SQL")
