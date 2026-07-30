#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[2]
objects = (
    "TVF_TruncateDate",
    "TVF_TruncateDateTime2",
    "TVF_TruncateDateTimeOffset",
)
required = [
    "Deployment/Deploy.sql",
    "Deployment/Uninstall.sql",
    "Examples/DateTimeTruncate.sql",
    "README.md",
    "Tests/DATETIME_TRUNCATE_CONTRACT_TEST_MATRIX.md",
    "Tests/README.md",
    "Tests/Runtime/DateTimeTruncate.Contract.sql",
    "Tests/Runtime/Lifecycle.Contract.sql",
    "Tests/Runtime/Central.Contract.sql",
    "module.yaml",
]
required += [f"Source/{name}.sql" for name in objects]
required += [f"Documentation/{name}.md" for name in objects]
missing = [path for path in required if not (root / path).is_file()]
if missing:
    raise SystemExit("Fehlende Artefakte: " + ", ".join(missing))

source = "\n".join((root / f"Source/{name}.sql").read_text("utf-8") for name in objects)
if source.count("RETURNS TABLE") != 3:
    raise SystemExit("Alle drei Truncation-Objekte müssen Inline TVFs sein.")
for marker in (
    "DATEPART(weekday",
    "iso_week",
    "ValidationCode",
    "datetimeoffset(7)",
):
    if marker not in source:
        raise SystemExit(f"Truncation-Vertragsmarker fehlt: {marker}")

print("Date/Time Truncation statische Vertragsprüfung: erfolgreich")
