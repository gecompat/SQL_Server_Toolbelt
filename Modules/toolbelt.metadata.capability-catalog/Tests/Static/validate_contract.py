#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[2]
required = (
    "Source/VW_ModuleCapabilities.sql",
    "Deployment/Deploy.sql",
    "Deployment/Uninstall.sql",
    "Examples/ModuleCapabilities.sql",
    "README.md",
    "Documentation/VW_ModuleCapabilities.md",
    "Tests/CAPABILITY_CATALOG_CONTRACT_TEST_MATRIX.md",
    "Tests/README.md",
    "Tests/Runtime/ModuleCapabilities.Contract.sql",
    "Tests/Runtime/Lifecycle.Contract.sql",
    "Tests/Runtime/Central.Contract.sql",
    "module.yaml",
)
missing = [path for path in required if not (root / path).is_file()]
if missing:
    raise SystemExit("Fehlende Artefakte: " + ", ".join(missing))

source = (root / "Source/VW_ModuleCapabilities.sql").read_text("utf-8")
for marker in (
    "CREATE OR ALTER VIEW [toolbelt_metadata].[VW_ModuleCapabilities]",
    "FROM sys.extended_properties AS ep",
    "ep.class = 0",
    "N'Toolbelt.Module.'",
    "ModuleVersion",
    "DeploymentMode",
    "MetadataStatus",
    "'incomplete'",
    "'invalid'",
    "'valid'",
):
    if marker not in source:
        raise SystemExit(f"Capability-Catalog-Vertragsmarker fehlt: {marker}")

for forbidden in ("CREATE TABLE", "INSERT INTO", "UPDATE ", "DELETE FROM"):
    if forbidden in source:
        raise SystemExit(
            "Die Capability-View darf keine persistente Registry oder Mutation "
            f"enthalten: {forbidden}"
        )

print("Module Capability Catalog statische Vertragsprüfung: erfolgreich")
