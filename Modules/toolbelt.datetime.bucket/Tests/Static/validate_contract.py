#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[2]
objects = (
    "TVF_DateBucketDate",
    "TVF_DateBucketDateTime2",
    "TVF_DateBucketDateTimeOffset",
)
required = [
    "Deployment/Deploy.sql",
    "Deployment/Uninstall.sql",
    "Examples/DateTimeBucket.sql",
    "README.md",
    "Tests/DATETIME_BUCKET_CONTRACT_TEST_MATRIX.md",
    "Tests/README.md",
    "Tests/Runtime/DateTimeBucket.Contract.sql",
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
    raise SystemExit("Alle drei Bucket-Objekte müssen Inline TVFs sein.")
for marker in ("DATEDIFF_BIG", "BucketIndex", "ValidationCode", "@Origin"):
    if marker not in source:
        raise SystemExit(f"Bucket-Vertragsmarker fehlt: {marker}")

print("Date/Time Bucket statische Vertragsprüfung: erfolgreich")
