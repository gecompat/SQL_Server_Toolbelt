#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
REPO = ROOT.parents[1]

def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

def main() -> int:
    parser = read("Source/TVF_ParseSemanticVersion.sql")
    comparator_tvf = read("Source/TVF_CompareSemanticVersion.sql")
    sort_key_tvf = read("Source/TVF_SemanticVersionSortKey.sql")
    comparator_svf = read("Source/SVF_CompareSemanticVersion.sql")
    sort_key_svf = read("Source/SVF_SemanticVersionSortKey.sql")
    deploy = read("Deployment/Deploy.sql")
    runtime = read("Tests/Runtime/SemanticVersion.Contract.sql")
    manifest = read("module.yaml")
    required = {
        "parser": (parser, ["TVF_ParseSemanticVersion", "varchar(8000)", "CORE_LEADING_ZERO", "PRERELEASE_LEADING_ZERO", "Latin1_General_100_BIN2"]),
        "comparator TVF": (comparator_tvf, ["TVF_CompareSemanticVersion", "RETURNS TABLE", "TVF_ParseSemanticVersion", "DATALENGTH", "ComparisonResult"]),
        "sort key TVF": (sort_key_tvf, ["TVF_SemanticVersionSortKey", "RETURNS TABLE", "CONVERT", "TVF_ParseSemanticVersion", "SortKey"]),
        "comparator SVF": (comparator_svf, ["SVF_CompareSemanticVersion", "RETURNS smallint", "TVF_CompareSemanticVersion"]),
        "sort key SVF": (sort_key_svf, ["SVF_SemanticVersionSortKey", "RETURNS varbinary(max)", "TVF_SemanticVersionSortKey"]),
        "deploy": (deploy, ["TVF_ParseSemanticVersion.sql", "TVF_CompareSemanticVersion.sql", "TVF_SemanticVersionSortKey.sql", "SVF_CompareSemanticVersion.sql", "SVF_SemanticVersionSortKey.sql", "51088"]),
        "runtime": (runtime, ["1.0.0-alpha", "1.0.0-rc.1", "@Huge", "CompatibilityLevel", "SVF-/inline-TVF-Parität", "OUTER APPLY"]),
        "manifest": (manifest, ['module_id: "toolbelt.validation.semantic-version"', '"51080-51089"', "SemanticVersionSortKey"]),
    }
    for name, (text, markers) in required.items():
        for marker in markers:
            if marker not in text:
                raise RuntimeError(f"{name}: Pflichtmarker fehlt: {marker}")
    if any(token in parser for token in ("TRY_CONVERT(bigint", "REGEXP_", "OPENJSON")):
        raise RuntimeError("Parser enthält einen unzulässigen numerischen oder versionsgebundenen Provider.")
    if "SVF_" in comparator_tvf or "SVF_" in sort_key_tvf:
        raise RuntimeError("Eine inline TVF darf nicht die zugehörige SVF aufrufen.")
    if "'IF'" not in read("Tests/Runtime/Lifecycle.Contract.sql"):
        raise RuntimeError("Lifecycle prüft den inline-TVF-Objekttyp nicht.")
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
