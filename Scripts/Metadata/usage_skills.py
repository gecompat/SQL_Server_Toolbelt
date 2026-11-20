"""Kanonische Usage-Skill-Dateien lesen und als konstante SQL-Sicht erzeugen.

Das YAML-Frontmatter verwendet JSON-kompatible Werte. Damit bleiben Listen,
Unicode und Defaults ohne zusätzliche Runtimebibliothek eindeutig lesbar.
Beschreibungsdaten führen keine Objekt-/Installations-/Rechteprüfung aus.
"""
from __future__ import annotations

from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import re

FORMAT_VERSION = "1.0"
SECTIONS = (
    "Zweck und Einsatzfälle", "Voraussetzungen", "Parameter und Zugriff",
    "Ergebnisse", "Aufrufbeispiele", "Rechte", "Ressourcenbedarf",
    "Nebenwirkungen", "Fehlerbehandlung", "Aussagegrenzen",
)
FIELDS = {
    "name", "description", "skill_format_version", "module_id", "schema_name",
    "object_name", "object_type", "database_role", "is_internal", "parameters",
    "source_paths", "review_status",
}
OPTIONAL_FIELDS = {"public_entrypoints", "source_module_version"}
PARAMETER_FIELDS = {
    "name", "sql_type", "sql_default", "is_output", "argument_required",
    "business_required", "nullable", "description",
}


def require(value, message):
    if not value:
        raise ValueError("USAGE_SKILL: " + message)


def units(value: str) -> int:
    return len(value.encode("utf-16-le")) // 2


@dataclass(frozen=True)
class Skill:
    metadata: dict
    markdown: str
    source: Path | None = None

    @property
    def identity(self):
        m = self.metadata
        return m["database_role"], m["schema_name"], m["object_name"]

    @property
    def sha256(self):
        return hashlib.sha256(self.markdown.encode("utf-8")).hexdigest()


def parse_frontmatter(markdown: str):
    require(markdown.startswith("---\n") and "\r" not in markdown,
            "UTF-8/LF und YAML-Frontmatter erforderlich")
    stop = markdown.find("\n---\n", 4)
    require(stop >= 4, "Frontmatter-Abschluss fehlt")
    header = markdown[4:stop]
    decoder, offset, result = json.JSONDecoder(), 0, {}
    while offset < len(header):
        while offset < len(header) and header[offset].isspace():
            offset += 1
        if offset == len(header):
            break
        key = re.match(r"([a-z][a-z0-9_]*):[ \t]*", header[offset:])
        require(key is not None, "Frontmatter-Schlüssel/Wert nicht kanonisch")
        require(key[1] not in result, "Doppelter Frontmatter-Schlüssel: " + key[1])
        offset += key.end()
        value, used = decoder.raw_decode(header[offset:])
        offset += used
        require(offset == len(header) or header[offset] == "\n",
                "Werte müssen JSON-kompatible YAML-Werte sein")
        result[key[1]] = value
    return result, markdown[stop + 5:]


def validate(skill: Skill, *, verified=True):
    m = skill.metadata
    require(FIELDS <= m.keys() and m.keys() <= FIELDS | OPTIONAL_FIELDS,
            "Frontmatter-Felder unvollständig oder unbekannt")
    require(m["skill_format_version"] == FORMAT_VERSION, "Unbekannte Formatversion")
    require(isinstance(m["name"], str)
            and re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", m["name"]) is not None
            and len(m["name"]) <= 64, "Skillname")
    for field, minimum, maximum in (
        ("schema_name", 0, 128), ("object_name", 1, 128),
        ("object_type", 1, 60), ("database_role", 1, 128),
        ("description", 1, 4000),
    ):
        value = m[field]
        require(isinstance(value, str) and minimum <= units(value) <= maximum
                and not any(ord(c) < 32 for c in value), "Feldlänge/Inhalt: " + field)
    require(type(m["is_internal"]) is bool, "IsInternal ist boolesch")
    require(re.fullmatch(r"[A-Z][A-Z0-9_]*", m["object_type"]), "Objekttyp ist ein technischer Code")
    require(m["review_status"] in ("draft", "verified"), "Reviewstatus")
    require(not verified or m["review_status"] == "verified", "Ungeprüfter Skill")
    require(isinstance(m["module_id"], str)
            and re.fullmatch(r"toolbelt\.[a-z0-9.-]+", m["module_id"]), "Modulidentität")
    require(isinstance(m["source_paths"], list) and m["source_paths"], "Quellreferenzen")
    for path in m["source_paths"]:
        require(isinstance(path, str) and not Path(path).is_absolute()
                and ".." not in path.split("/") and "\\" not in path and ":" not in path,
                "Quellreferenz muss repositoryrelativ sein")
        require(path.startswith(("Modules/", "Scripts/", "Documentation/", "Metadata/UsageSkills/")),
                "Private/unbekannte Quellreferenz")
    require(isinstance(m["parameters"], list), "Parameterliste")
    seen = set()
    for p in m["parameters"]:
        require(isinstance(p, dict) and set(p) == PARAMETER_FIELDS, "Parameterfelder")
        require(isinstance(p["name"], str) and re.fullmatch(r"@\w+", p["name"])
                and p["name"].casefold() not in seen, "Parameteridentität")
        seen.add(p["name"].casefold())
        require(isinstance(p["sql_type"], str) and p["sql_type"]
                and isinstance(p["description"], str) and p["description"].strip(), "Parametervertrag")
        require(p["sql_default"] is None or isinstance(p["sql_default"], str), "SQL-Default")
        for key in ("is_output", "argument_required", "business_required", "nullable"):
            unresolved = (m["review_status"] == "draft" and not verified
                          and key in ("business_required", "nullable") and p[key] is None)
            require(type(p[key]) is bool or unresolved, "Parameterflag: " + key)
    if m["is_internal"]:
        require(isinstance(m.get("public_entrypoints"), list) and m["public_entrypoints"],
                "Interne Objekte benötigen öffentliche Einstiege")
    parsed, body = parse_frontmatter(skill.markdown)
    for section in SECTIONS:
        found = re.search(r"(?m)^## " + re.escape(section) + r"\n([\s\S]*?)(?=^## |\Z)", body)
        require(found is not None and found[1].strip(), "Abschnitt fehlt: " + section)
    require("```sql\n" in body and "\x00" not in skill.markdown, "SQL-Beispiel/Unicode-Inhalt")
    require(parsed == m, "Frontmatter und projizierte Metadaten unterscheiden sich")
    return skill


def read(path: Path, *, verified=True):
    raw = path.read_bytes()
    require(not raw.startswith(b"\xef\xbb\xbf"), "UTF-8 ohne BOM erforderlich")
    markdown = raw.decode("utf-8")
    metadata, _ = parse_frontmatter(markdown)
    return validate(Skill(metadata, markdown, path), verified=verified)


def write(path: Path, metadata: dict, sections: dict):
    require(set(sections) == set(SECTIONS), "Abschnittsinventar")
    header = "\n".join(key + ": " + json.dumps(value, ensure_ascii=False)
                       for key, value in metadata.items())
    body = "\n\n".join("## " + key + "\n\n" + sections[key].strip() for key in SECTIONS)
    text = "---\n" + header + "\n---\n\n# " + metadata["object_name"] + "\n\n" + body + "\n"
    validate(Skill(metadata, text), verified=False)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")
    return Skill(metadata, text, path)


def sql_literal(text: str):
    chunks, current, length = [], "", 0
    for char in text:
        width = units(char)
        if length + width > 2000:
            chunks.append(current)
            current, length = "", 0
        current += char
        length += width
    chunks.append(current)
    values = ["N'" + chunk.replace("'", "''") + "'" for chunk in chunks]
    values[0] = "CAST(" + values[0] + " AS nvarchar(max))"
    return " + ".join(values)


def inventory(root: Path):
    """Das deklarierte persistente Objektinventar, keine Laufzeitentdeckung."""
    import sys
    sys.path.insert(0, str(root / "Scripts/Install"))
    import markerless_manifest as manifest
    result = {}
    allowed = {"USP", "CLR_USP", "TVF", "CLR_TVF", "SVF", "CLR_SVF",
               "VIEW", "VW", "TABLE", "ASSEMBLY", "CLR_AGGREGATE"}
    for path in sorted((root / "Modules").glob("*/module.yaml")):
        text = path.read_text(encoding="utf-8-sig")
        module = manifest.scalar(text, "module_id")
        objects = manifest.objects(text)
        for obj in objects:
            require(obj["type"] in allowed, "Nicht klassifizierter Inventartyp")
            require(obj.get("visibility") in ("public", "internal", "configuration"), "Objektsichtbarkeit")
            schema = obj.get("schema", "")
            require(schema or obj["type"] == "ASSEMBLY", "Schemafreie Objektart")
            identity = ("toolbelt", schema, obj["name"])
            require(identity not in result, "Doppeltes kanonisches Objekt")
            result[identity] = dict(module_id=module, object_type=obj["type"],
                                    is_internal=obj["visibility"] == "internal",
                                    source_module_version=manifest.scalar(text, "version"))
        clr = manifest.section(text, "clr")
        if clr and manifest.scalar(clr, "  used") == "true":
            declared = ("toolbelt", "", manifest.scalar(clr, "  assembly_sql_name"))
            require(declared in result, "Eigene CLR-Assembly fehlt im Objektinventar: " + module)
    # Explicitly approved new API; its source/manifest registration is coupled
    # to full generation, not falsely treated as an already installed object.
    own = ("toolbelt", "toolbelt_metadata", "VW_ObjectUsageSkills")
    result.setdefault(own, dict(module_id="toolbelt.metadata.capability-catalog",
                                object_type="VW", is_internal=False,
                                source_module_version="1.0.0"))
    return result


def validate_coverage(skills, expected):
    seen = set()
    for skill in skills:
        validate(skill)
        require(skill.identity not in seen, "Mehrere Dateien für dieselbe Identität")
        seen.add(skill.identity)
        require(skill.identity in expected, "Nicht inventarisierter Skill")
        for key, value in expected[skill.identity].items():
            require(skill.metadata[key] == value, "Skill/Inventar widersprüchlich: " + key)
    missing = set(expected) - seen
    require(not missing, "Inventarabdeckung unvollständig: " + str(len(missing)) + " Objekte fehlen")
    return len(seen)


def render_view(skills, schema="toolbelt_metadata", *, require_self=True):
    require(re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", schema), "Metadatenschema")
    skills = tuple(skills)
    rows, identities, names = [], set(), set()
    for skill in sorted(skills, key=lambda s: s.identity):
        validate(skill)
        identity = tuple(part.casefold() for part in skill.identity)
        require(identity not in identities and skill.metadata["name"] not in names,
                "Doppelte Identität oder Skillname")
        identities.add(identity)
        names.add(skill.metadata["name"])
        m = skill.metadata
        row = [m["schema_name"], m["object_name"], m["object_type"], m["database_role"],
               m["is_internal"], m["description"], m["skill_format_version"], skill.markdown]
        rows.append("(" + ",".join(str(int(v)) if type(v) is bool else sql_literal(v) for v in row) + ")")
    require(rows, "Leeres Skillinventar")
    require(not require_self or any(s.metadata["schema_name"] == schema
            and s.metadata["object_name"] == "VW_ObjectUsageSkills" for s in skills),
            "Selbstbeschreibung der Skill-View fehlt")
    return ("CREATE OR ALTER VIEW [" + schema + "].[VW_ObjectUsageSkills]\nAS\nSELECT\n"
            " CONVERT(sysname,v.SchemaName) AS SchemaName,\n"
            " CONVERT(sysname,v.ObjectName) AS ObjectName,\n"
            " CONVERT(varchar(60),v.ObjectType) AS ObjectType,\n"
            " CONVERT(nvarchar(128),v.DatabaseRole) AS DatabaseRole,\n"
            " CONVERT(bit,v.IsInternal) AS IsInternal,\n"
            " CONVERT(nvarchar(4000),v.Description) AS Description,\n"
            " CONVERT(varchar(16),v.SkillFormatVersion) AS SkillFormatVersion,\n"
            " CONVERT(nvarchar(max),v.SkillMarkdown) AS SkillMarkdown\n"
            "FROM (VALUES\n" + ",\n".join(rows) +
            "\n)v(SchemaName,ObjectName,ObjectType,DatabaseRole,IsInternal,Description,SkillFormatVersion,SkillMarkdown);\n")
