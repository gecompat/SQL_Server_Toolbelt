"""Prepare exact catalogue expectations for the native consumer checker."""
import argparse
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Metadata"))
import usage_skills


def expectations(root):
    for record in usage_skills.load_catalogue(root):
        metadata = record.metadata
        yield {
            "SchemaName": metadata["schema_name"],
            "ObjectName": metadata["object_name"],
            "ObjectType": metadata["object_type"],
            "DatabaseRole": metadata["database_role"],
            "IsInternal": metadata["is_internal"],
            "Description": metadata["description"],
            "SkillFormatVersion": metadata["skill_format_version"],
            "SkillMarkdown": record.markdown,
        }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    rows = sorted(expectations(ROOT), key=lambda r: (r["DatabaseRole"], r["SchemaName"], r["ObjectName"]))
    with args.output.open("x", encoding="utf-8", newline="\n") as target:
        json.dump(rows, target, ensure_ascii=False)
        target.write("\n")
    print(f"USAGE_SKILL_EXPECTATIONS_WRITTEN rows={len(rows)}")
