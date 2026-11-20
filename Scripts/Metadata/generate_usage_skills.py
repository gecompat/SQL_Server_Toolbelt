"""Geprüfte Skillquellen gegen das vollständige Inventar prüfen und SQL erzeugen."""
import argparse
from pathlib import Path

import usage_skills

ROOT = Path(__file__).resolve().parents[2]


def generate(root=ROOT, output=None):
    files = sorted((root / "Metadata/UsageSkills").glob("*/*.md"))
    records = [usage_skills.read(path) for path in files]
    expected = usage_skills.inventory(root)
    # No partial output or implicit success while source coverage is incomplete.
    count = usage_skills.validate_coverage(records, expected)
    sql = usage_skills.render_view(records)
    if output is not None:
        output = Path(output)
        usage_skills.require(not output.exists(), "Neue Ausgabedatei erforderlich")
        output.parent.mkdir(parents=True, exist_ok=True)
        with output.open("x", encoding="utf-8", newline="\n") as stream:
            stream.write(sql)
    return count


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    print("USAGE_SKILLS_COMPLETE objects=" + str(generate(output=args.output)) + "; no SQL executed")
