#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[2]
public_objects = (
    "TVF_DateSpineDay",
    "TVF_DateSpineIsoWeek",
    "TVF_DateSpineMonth",
)
all_objects = ("TVF_DateSpineCore",) + public_objects
required = [
    "Deployment/Deploy.sql",
    "Deployment/Uninstall.sql",
    "Examples/DateSpine.sql",
    "README.md",
    "Tests/DATE_SPINE_CONTRACT_TEST_MATRIX.md",
    "Tests/README.md",
    "Tests/Runtime/DateSpine.Contract.sql",
    "Tests/Runtime/Lifecycle.Contract.sql",
    "Tests/Runtime/Central.Contract.sql",
    "module.yaml",
]
required += [f"Source/{name}.sql" for name in all_objects]
required += [f"Documentation/{name}.md" for name in all_objects]

missing = [path for path in required if not (root / path).is_file()]
if missing:
    raise SystemExit("Fehlende Artefakte: " + ", ".join(missing))

source = "\n".join(
    (root / f"Source/{name}.sql").read_text("utf-8")
    for name in all_objects
)
if source.count("RETURNS TABLE") != 4:
    raise SystemExit("Alle vier Date-Spine-Objekte müssen Inline TVFs sein.")
for marker in (
    "TVF_GenerateSeriesInt",
    "TVF_TruncateDate",
    "Latin1_General_100_BIN2",
    "@RangeEndExclusive",
    "Ordinal",
    "PeriodStart",
):
    if marker not in source:
        raise SystemExit(f"Date-Spine-Vertragsmarker fehlt: {marker}")
if "TVF_DateBucket" in source:
    raise SystemExit("Date Spine darf keine künstliche Bucket-Dependency besitzen.")
for object_name in public_objects:
    wrapper = (root / f"Source/{object_name}.sql").read_text("utf-8")
    if "TVF_DateSpineCore" not in wrapper:
        raise SystemExit(f"Öffentlicher Wrapper umgeht den Kern: {object_name}")

print("Date-Spine statische Vertragsprüfung: erfolgreich")
