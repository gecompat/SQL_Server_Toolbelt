#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
REPO = ROOT.parents[1]

def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

def main() -> int:
    parser = read("Source/TVF_ParseSemanticVersion.sql")
    comparator = read("Source/SVF_CompareSemanticVersion.sql")
    sort_key = read("Source/SVF_SemanticVersionSortKey.sql")
    deploy = read("Deployment/Deploy.sql")
    runtime = read("Tests/Runtime/SemanticVersion.Contract.sql")
    manifest = read("module.yaml")
    required = {
        "parser": (parser, ["TVF_ParseSemanticVersion", "varchar(8000)", "CORE_LEADING_ZERO", "PRERELEASE_LEADING_ZERO", "Latin1_General_100_BIN2"]),
        "comparator": (comparator, ["SVF_CompareSemanticVersion", "RETURNS smallint", "TVF_ParseSemanticVersion", "DATALENGTH"]),
        "sort key": (sort_key, ["SVF_SemanticVersionSortKey", "RETURNS varbinary(max)", "CONVERT(binary(2)", "TVF_ParseSemanticVersion"]),
        "deploy": (deploy, ["TVF_ParseSemanticVersion.sql", "SVF_CompareSemanticVersion.sql", "SVF_SemanticVersionSortKey.sql", "51088"]),
        "runtime": (runtime, ["1.0.0-alpha", "1.0.0-rc.1", "@Huge", "CompatibilityLevel"]),
        "manifest": (manifest, ['module_id: "toolbelt.validation.semantic-version"', '"51080-51089"', "SemanticVersionSortKey"]),
    }
    for name, (text, markers) in required.items():
        for marker in markers:
            if marker not in text:
                raise RuntimeError(f"{name}: Pflichtmarker fehlt: {marker}")
    if any(token in parser for token in ("TRY_CONVERT(bigint", "REGEXP_", "OPENJSON")):
        raise RuntimeError("Parser enthält einen unzulässigen numerischen oder versionsgebundenen Provider.")
    if "SET QUOTED_IDENTIFIER ON;" not in deploy or "QUOTED_SEMANTIC_VERSION" in deploy:
        raise RuntimeError("Deploy enthält keine kanonische QUOTED_IDENTIFIER-Option.")
    workflow = (REPO / ".github/workflows/semantic-version-runtime.yml").read_text(encoding="utf-8")
    if "Documentation/**" in workflow:
        raise RuntimeError("Runtime-Workflow wird durch reine Dokumentation ausgelöst.")
    print("Semantic-Version statische Vertragsprüfung: erfolgreich")
    return 0

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as error:
        print(f"Semantic-Version statische Vertragsprüfung: FEHLER: {error}", file=sys.stderr)
        raise SystemExit(1)
