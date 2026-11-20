"""Einmalige Migration vorhandener öffentlicher Beschreibungen als Reviewentwürfe.

Keine neue Semantik wird geraten und kein Entwurf als geprüft ausgeliefert.
Vorhandene redaktionelle Skilldateien werden weder ersetzt noch zurückgesetzt.
"""
from pathlib import Path
import hashlib
import json
import re
import sys

import usage_skills

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Tests/Documentation"))
import generate_api_catalog as catalog


def slug(identity):
    value = "toolbelt-" + "-".join(identity).lower().replace("_", "-").replace(".", "-")
    value = re.sub(r"-+", "-", value).strip("-")
    if len(value) > 64:
        value = value[:55].rstrip("-") + "-" + hashlib.sha256("/".join(identity).encode()).hexdigest()[:8]
    return value


def bootstrap(root=ROOT):
    registry = json.loads((root / "Documentation/Reference/api_examples.json").read_bytes())
    helpdata = json.loads((root / "Documentation/Reference/usp_help.json").read_bytes())
    created = 0
    for item in catalog.objects(root):
        key = item["schema"] + "." + item["name"]
        output = root / "Metadata/UsageSkills" / item["schema"] / (item["name"] + ".md")
        if output.exists():
            continue
        source, actual = catalog.signature(item)
        entry = registry[key]
        parameters = []
        for p in actual:
            flags = helpdata.get(key, {}).get("parameters", {}).get(p["name"])
            # These are migrated declarations, not newly verified semantics.
            parameters.append(dict(
                name=p["name"], sql_type=p["type"],
                sql_default=None if p["default"] == "kein Default" else p["default"],
                is_output=p["output"],
                argument_required=(item["type"] != "USP" or p["default"] == "kein Default"),
                business_required=flags[0] if flags else None,
                nullable=flags[1] if flags else None,
                description=entry["parameter_notes"][p["name"]],
            ))
        metadata = dict(
            name=slug(("toolbelt", item["schema"], item["name"])),
            description=entry["summary"], skill_format_version="1.0", module_id=item["module"],
            schema_name=item["schema"], object_name=item["name"], object_type=item["type"],
            database_role="toolbelt", is_internal=False, parameters=parameters,
            source_paths=[source.relative_to(root).as_posix()], review_status="draft",
            source_module_version=item["version"],
        )
        docs = catalog.documentation(item)
        links = "\n".join("- `" + p.relative_to(root).as_posix() + "`" for p in docs)
        rows = helpdata.get(key, {}).get("rows", [])
        by_section = {}
        for row in rows:
            by_section.setdefault(row[0], []).append(row[7])
        def existing(section):
            values = by_section.get(section)
            return "\n\n".join(values) if values else "Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen."
        sections = {
            "Zweck und Einsatzfälle": entry["summary"] + "\n\nReviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.",
            "Voraussetzungen": "\n".join("- " + r for r in entry["requirements"]) or "Noch gegen den Code zu prüfen.",
            "Parameter und Zugriff": catalog.parameter_table(actual, entry["parameter_notes"]) if actual else "Keine SQL-Aufrufparameter laut aktueller Source-Deklaration.",
            "Ergebnisse": existing("RESULT_COLUMN"),
            "Aufrufbeispiele": "\n\n".join("```sql\n" + sql + "\n```" for sql in entry["examples"]),
            "Rechte": existing("PERMISSION"),
            "Ressourcenbedarf": "Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.",
            "Nebenwirkungen": "Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.",
            "Fehlerbehandlung": existing("ERROR"),
            "Aussagegrenzen": existing("LIMITATION") + "\n\nUrsprüngliche Objektverträge:\n" + links + "\n\nKeine Installations-, Definitions- oder Rechteattestation.",
        }
        usage_skills.write(output, metadata, sections)
        created += 1
    return created


if __name__ == "__main__":
    print("USAGE_SKILL_REVIEW_DRAFTS_CREATED count=" + str(bootstrap()) + "; no SQL executed; drafts cannot ship")
