"""Begrenzte native Hostqualifikation mit festen Graph- und CLI-Orakeln.

Windows und Linux führen dieselben synthetischen Fälle mit demselben portablen
Hostbinary aus. Nur aggregierte Ergebnisse und öffentliche Quellpins werden
gespeichert; Modelloutputs bleiben in den kurzlebigen Testprozessen.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import tempfile
from datetime import datetime, timezone

MODULE = Path("Modules/toolbelt.tsql.ssis-debug")
METHOD = MODULE / "Exchange/Tests/qualify_host.py"
MODES = ("model", "bundle", "iteration-bundle", "scope-bundle", "pipeline-bundle")
CASE_NAMES = tuple(f"format{version}:{mode}" for version in (6, 8) for mode in MODES) + (
    "unicode-path-private-literal", "unknown-format", "prohibited-dtd",
    "malformed-xml", "wrong-extension", "missing-file", "usage",
)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def source_pins(root):
    paths = [METHOD, MODULE / "Exchange/Host/Program.cs",
             MODULE / "Exchange/Host/Toolbelt.Ssis.Export.csproj",
             MODULE / "Contracts/Exchange/Fixtures/direct-8.dtsx",
             MODULE / "Contracts/Exchange/Fixtures/direct-8.expected.json"]
    paths += sorted(p.relative_to(root) for p in (root / MODULE / "Exchange/Core").glob("*.cs"))
    return {p.as_posix(): sha((root / p).read_bytes()) for p in paths}


def qualify(root, host, dotnet, expected_platform):
    actual_platform = platform.system()
    if actual_platform != expected_platform or actual_platform not in ("Windows", "Linux"):
        raise ValueError("NATIVE_PLATFORM_MISMATCH")
    pins = source_pins(root)
    binary_hash = sha(host.read_bytes())
    fixture = (root / MODULE / "Contracts/Exchange/Fixtures/direct-8.dtsx").read_bytes()
    oracle = json.loads((root / MODULE / "Contracts/Exchange/Fixtures/direct-8.expected.json").read_text("utf-8"))
    env = dict(os.environ, DOTNET_CLI_TELEMETRY_OPTOUT="1", DOTNET_SKIP_FIRST_TIME_EXPERIENCE="1",
               DOTNET_MULTILEVEL_LOOKUP="0")
    cases = []
    source_commit = None
    with tempfile.TemporaryDirectory(prefix="ToolbeltSsisHost-") as temporary:
        stage = Path(temporary)

        def run(name, data, mode="model", error=None, missing=False, usage=False, extension=".dtsx"):
            nonlocal source_commit
            checks = 0

            def check(condition, label):
                nonlocal checks
                if not condition:
                    raise AssertionError(name + ":" + label)
                checks += 1

            path = stage / ("Synthetisch-Ä-汉" + extension)
            if not missing:
                path.write_bytes(data)
            arguments = [] if usage else (["--" + mode] if mode != "model" else []) + [str(path)]
            if missing:
                arguments = [str(stage / "absent.dtsx")]
            result = subprocess.run([str(dotnet), str(host), *arguments], capture_output=True,
                                    timeout=15, env=env)
            check(result.returncode == (error[0] if error else 0), "exit-code")
            stderr = result.stderr.decode("utf-8").strip()
            if error:
                check(not result.stdout, "no-partial-stdout")
                check(stderr.startswith(error[1]) if usage else stderr == error[1], "error-code")
                semantic_hash = sha(b"")
            else:
                check(not stderr, "empty-stderr")
                output = json.loads(result.stdout)
                model = output if mode == "model" else output["model"]
                check(model["contract"] == "ssis-package-model-components-v2", "current-contract")
                check(model["source"]["packageSha256"] == sha(data), "source-bytes")
                check(model["source"]["byteLength"] == len(data), "source-length")
                check(model["producer"]["buildSha256"] == binary_hash, "executed-binary")
                commit = model["producer"]["sourceCommit"]
                check(len(commit) == 40 and all(c in "0123456789abcdef" for c in commit), "source-commit")
                if source_commit is None:
                    source_commit = commit
                check(source_commit == commit, "single-source-commit")
                check(model["resourcePolicy"]["effectiveLimits"]["analysisMilliseconds"] == "unlimited",
                      "current-analysis-default")
                check([[n["id"], n["kind"], n["parentId"]] for n in model["nodes"]] == oracle["nodeSignatures"],
                      "independent-object-oracle")
                check([[e["kind"], e["fromId"], e["toId"], e["ruleId"]] for e in model["edges"]] == oracle["edgeSignatures"],
                      "independent-lineage-oracle")
                check(all(c["status"] == oracle["coverageStatus"] for c in model["coverage"]), "coverage")
                if name == "unicode-path-private-literal":
                    check(b"SYNTHETIC_PRIVATE_LITERAL" not in result.stdout, "private-literal-not-exported")
                if mode != "model":
                    check(output["contract"] == "ssis-export-bundle" and output["version"] == "1.0.0", "bundle-contract")
                    check("identities" in output, "identities-present")
                    if mode == "pipeline-bundle":
                        check("pipelineIdentities" in output, "pipeline-identities-present")
                semantic_hash = sha(json.dumps(output, ensure_ascii=True, sort_keys=True,
                                               separators=(",", ":")).encode("utf-8"))
            cases.append({"name": name, "exit_code": result.returncode,
                          "assertions": checks, "output_sha256": semantic_hash})

        for version in (6, 8):
            data = fixture.replace(b">8</DTS:Property>", f">{version}</DTS:Property>".encode("ascii"))
            for mode in MODES:
                run(f"format{version}:{mode}", data, mode)
        # Das Literal bleibt synthetisch; derselbe vorhandene Variablenknoten
        # erhält einen passenden Stringtyp und darf seinen Wert nicht exportieren.
        private = fixture.replace(b'DTS:DataType="3"', b'DTS:DataType="130"').replace(
            b">17</DTS:VariableValue>", b">SYNTHETIC_PRIVATE_LITERAL</DTS:VariableValue>")
        run("unicode-path-private-literal", private)
        invalid = (3, "TBX_SSISMODEL_UNSUPPORTED_PACKAGE_FORMAT")
        run("unknown-format", fixture.replace(b">8</DTS:Property>", b">99</DTS:Property>"), error=invalid)
        run("prohibited-dtd", b'<?xml version="1.0"?><!DOCTYPE x [<!ENTITY a "SYNTHETIC_PRIVATE_LITERAL">]>' + fixture.split(b"?>", 1)[1], error=invalid)
        run("malformed-xml", b"<broken>", error=invalid)
        run("wrong-extension", fixture, extension=".xml", error=invalid)
        run("missing-file", b"", missing=True, error=(4, "TBX_SSISMODEL_HOST_FAILURE"))
        run("usage", b"", usage=True, error=(2, "Usage: Toolbelt.Ssis.Export"))
    if tuple(c["name"] for c in cases) != CASE_NAMES or source_pins(root) != pins or sha(host.read_bytes()) != binary_hash:
        raise ValueError("INPUT_DRIFT")
    return {"contract": "ssis-export-host-native/1", "date": datetime.now(timezone.utc).date().isoformat(),
            "platform": actual_platform, "result": "PASS", "sql_executed": False,
            "host_sha256": binary_hash, "source_commit": source_commit, "source_sha256": pins,
            "case_count": len(cases), "assertions": sum(c["assertions"] for c in cases), "cases": cases}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", type=Path, required=True)
    parser.add_argument("--dotnet", type=Path, required=True)
    parser.add_argument("--platform", choices=("Windows", "Linux"), required=True)
    parser.add_argument("--result", type=Path, required=True)
    args = parser.parse_args()
    report = qualify(Path(__file__).resolve().parents[4], args.host.resolve(), args.dotnet.resolve(), args.platform)
    args.result.write_text(json.dumps(report, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")
    print(f"SSIS_EXPORT_HOST_PASS platform={report['platform']} cases={report['case_count']} assertions={report['assertions']}")


if __name__ == "__main__":
    main()
