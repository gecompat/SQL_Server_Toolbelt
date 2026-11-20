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
    require("```sql\n" in body and "\x00" not in skill.markdown
            and skill.markdown.endswith("\n"), "SQL-Beispiel/Unicode-Inhalt/abschließendes LF")
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


DDL_BEGIN = "-- OBJECT_USAGE_SKILL:BEGIN"
DDL_END = "-- OBJECT_USAGE_SKILL:END"
HELP_BEGIN = "-- OBJECT_USAGE_SKILL_HELP:BEGIN"
HELP_END = "-- OBJECT_USAGE_SKILL_HELP:END"


def render_ddl_comment(skill: Skill):
    """Vollständigen Originaltext als passive Zeilenkommentare transportieren.

    Markdown darf SQL-Beispiele, Blockkommentar-Enden und GO enthalten. Ein
    Blockkommentar wäre deshalb keine sichere, verlustfreie Einbettung.
    """
    validate(skill)
    return (DDL_BEGIN + "\n"
            + "".join(("-- " + line if line else "--") + "\n"
                      for line in skill.markdown.split("\n")[:-1])
            + DDL_END + "\n")


def read_ddl_comment(text: str):
    """Genau einen markierten Kommentar zurücklesen; keine SQL-Auswertung."""
    lines = text.split("\n")
    starts = [i for i, line in enumerate(lines) if line == DDL_BEGIN]
    ends = [i for i, line in enumerate(lines) if line == DDL_END]
    require(len(starts) == len(ends) == 1 and starts[0] < ends[0],
            "DDL-Skillmarkierungen fehlen, sind doppelt oder vertauscht")
    body = lines[starts[0] + 1:ends[0]]
    require(body and all(line == "--" or line.startswith("-- ") for line in body),
            "DDL-Skillkommentar ist nicht kanonisch")
    markdown = "".join(("" if line == "--" else line[3:]) + "\n" for line in body)
    metadata, _ = parse_frontmatter(markdown)
    return validate(Skill(metadata, markdown))


def render_help_resultset(skill: Skill):
    """Zusätzliches konstantes Resultset; Caller setzt frühen RETURN selbst.

    Der Renderer ersetzt keine vorhandene Hilfe und initialisiert weder
    OUTPUT-Parameter noch Caller-Zustand. Die Einbindung liegt im Hilfezweig.
    """
    validate(skill)
    m = skill.metadata
    require(m["object_type"] in ("USP", "CLR_USP"), "Skillhilfe benötigt eine Prozedur")
    return ("SELECT CONVERT(varchar(16)," + sql_literal(m["skill_format_version"])
            + ") AS SkillFormatVersion,\n"
            + " CONVERT(sysname," + sql_literal(m["schema_name"]) + ") AS SchemaName,\n"
            + " CONVERT(sysname," + sql_literal(m["object_name"]) + ") AS ObjectName,\n"
            + " " + sql_literal(skill.markdown) + " AS SkillMarkdown;\n")


def strip_ddl_projection(root: Path, path: str, text: str):
    """Nur exakt kanonische, quellzugeordnete Skillkommentare ausblenden.

    Dies beweist allein die Gleichheit des verbleibenden Fachtexts. Neue
    Metadaten-/Hilfefunktionalität erhält dadurch keinen historischen PASS.
    """
    if DDL_BEGIN not in text and DDL_END not in text:
        return text
    projected = read_ddl_comment(text)
    m = projected.metadata
    folder = (root / "Metadata/UsageSkills").resolve()
    source = folder / m["schema_name"] / (m["object_name"] + ".md")
    require(source.resolve().is_relative_to(folder), "Skillquelle außerhalb des Katalogs")
    canonical = read(source)
    require(canonical.markdown == projected.markdown
            and m["source_paths"][0] == path, "DDL-Skill ist nicht kanonisch/quellzugeordnet")
    comment = render_ddl_comment(canonical)
    require(text.count(comment) == 1, "DDL-Skillkommentar nicht eindeutig/bytegleich")
    return text.replace(comment, "", 1)


def _ddl_tokens(text):
    """Positionslexer für die begrenzte Inline-TVF-Projektion, kein SQL-Parser."""
    result, pos = [], 0
    while pos < len(text):
        if text[pos].isspace():
            pos += 1
        elif text.startswith("--", pos):
            end = text.find("\n", pos)
            pos = len(text) if end < 0 else end + 1
        elif text.startswith("/*", pos):
            depth, pos = 1, pos + 2
            while depth and pos < len(text):
                if text.startswith("/*", pos):
                    depth, pos = depth + 1, pos + 2
                elif text.startswith("*/", pos):
                    depth, pos = depth - 1, pos + 2
                else:
                    pos += 1
            require(depth == 0, "Unvollständiger DDL-Kommentar")
        else:
            start = pos
            token = re.match(r"N?'(?:[^']|'')*'|\[(?:[^\]]|\]\])*\]|[A-Za-z_@][A-Za-z_0-9@]*|.", text[pos:], re.S)
            require(token is not None, "DDL-Token")
            value = token[0]
            require(value not in ("'", "[", '"'), "Unvollständiger/nicht unterstützter DDL-Token")
            pos += len(value)
            result.append((value, start, pos))
    return result


def _procedure_help_return(text: str, skill: Skill):
    """Bestehenden positiven Hilfezweig mit genau einem finalen RETURN binden."""
    require(skill.metadata["object_type"] == "USP", "T-SQL-Prozedur erforderlich")
    ts = _ddl_tokens(text)
    words = [t[0].casefold() for t in ts]
    creates = [i for i, word in enumerate(words) if word == "create"]
    require(len(creates) == 1, "Genau eine Prozedurdeklaration erforderlich")
    i = creates[0] + 1
    if words[i:i + 2] == ["or", "alter"]:
        i += 2
    m = skill.metadata
    require(words[i] in ("procedure", "proc")
            and [w.strip("[]") for w in words[i + 1:i + 4]]
            == [m["schema_name"].casefold(), ".", m["object_name"].casefold()],
            "Prozedur-/Skillidentität")
    patterns = (["if", "@hilfe", "=", "1", "begin"],
                ["if", "isnull", "(", "@hilfe", ",", "0", ")", "=", "1", "begin"])
    branches = [j + len(p) - 1 for j in range(i + 4, len(words)) for p in patterns
                if words[j:j + len(p)] == p]
    require(len(branches) == 1, "Genau ein unterstützter positiver Hilfezweig erforderlich")
    start = branches[0]
    level, returns, j = 1, [], start + 1
    while j < len(words) and level:
        word = words[j]
        if word in ("begin", "case"):
            level += 1
        elif word == "end":
            level -= 1
        elif word == "return":
            returns.append((j, level))
        j += 1
    require(level == 0 and len(returns) == 1 and returns[0][1] == 1,
            "Hilfezweig benötigt genau einen direkten RETURN")
    ret = returns[0][0]
    require(words[ret:j - 1] == ["return", "0", ";"], "Hilfe-RETURN muss abschließend RETURN 0; sein")
    line = text.rfind("\n", 0, ts[ret][1]) + 1
    require(not text[line:ts[ret][1]].strip(), "Hilfe-RETURN muss eigene Zeile besitzen")
    return line, ts[ret][1] - line


def render_help_projection(skill: Skill, indent=8):
    require(type(indent) is int and 0 <= indent <= 64, "Hilfe-Einrückung")
    # SQL literals contain the original multi-line Markdown. Indenting every
    # physical line would silently modify its values, not merely SQL layout.
    return (" " * indent + HELP_BEGIN + "\n" + render_help_resultset(skill)
            + " " * indent + HELP_END + "\n")


def project_procedure_help(text: str, skill: Skill):
    """Zusätzlichen konstanten SELECT unmittelbar vor frühem RETURN einfügen."""
    validate(skill)
    marked = re.search(r"(?m)^[ \t]*" + re.escape(HELP_BEGIN) + r"$", text)
    if marked:
        line, indent = _procedure_help_return(text, skill)
        block = render_help_projection(skill, indent)
        require(text.count(block) == 1 and text[:line].endswith(block),
                "Vorhandene Skillhilfe ist nicht kanonisch oder steht vor falschem RETURN")
        return text
    require(not re.search(r"(?m)^[ \t]*" + re.escape(HELP_END) + r"$", text),
            "Unvollständige Skillhilfe-Markierungen")
    line, indent = _procedure_help_return(text, skill)
    return text[:line] + render_help_projection(skill, indent) + text[line:]


def strip_help_projection(root: Path, path: str, text: str):
    """Nur die kanonische zusätzliche Hilfe entfernen, nie den alten Hilfezweig."""
    if not re.search(r"(?m)^[ \t]*" + re.escape(HELP_BEGIN) + r"$", text):
        return text
    projected = read_ddl_comment(text)
    # Bind exact editorial bytes, primary source and existing positive help guard.
    strip_ddl_projection(root, path, text)
    require(project_procedure_help(text, projected) == text, "Nicht kanonische Hilfeprojektion")
    _, indent = _procedure_help_return(text, projected)
    return text.replace(render_help_projection(projected, indent), "", 1)


def project_procedure_ddl(text: str, skill: Skill):
    """Passiven Skillkommentar vor dem äußeren BEGIN eines T-SQL-USP einfügen."""
    validate(skill)
    _procedure_help_return(text, skill)
    if re.search(r"(?m)^" + re.escape(DDL_BEGIN) + r"$", text):
        require(read_ddl_comment(text).markdown == skill.markdown, "Vorhandener DDL-Skill weicht ab")
        return text
    ts = _ddl_tokens(text)
    anchors = [j for j in range(len(ts) - 1)
               if ts[j][0].casefold() == "as" and ts[j + 1][0].casefold() == "begin"]
    require(len(anchors) == 1, "Eindeutiges AS BEGIN für Prozedur erforderlich")
    end = ts[anchors[0]][2]
    require(text[end:end + 1] == "\n", "AS muss mit LF abschließen")
    return text[:end + 1] + render_ddl_comment(skill) + text[end + 1:]


def project_inline_function(text: str, skill: Skill):
    """Skill nach AS einer einzelnen Inline-TVF einfügen, Fachbytes erhalten.

    Andere Objektarten/Definitionen brauchen eigene explizite Adapter. Vorhandene
    Projektionen werden nur erkannt, niemals still in neue Texte umgeschrieben.
    """
    validate(skill)
    require(skill.metadata["object_type"] == "TVF", "Inline-TVF-Skill erforderlich")
    comment = render_ddl_comment(skill)
    if DDL_BEGIN in text or DDL_END in text:
        current = read_ddl_comment(text)
        require(current.markdown == skill.markdown and text.count(comment) == 1,
                "Vorhandener DDL-Skill weicht ab; explizite Regeneration erforderlich")
        return text
    tokens = _ddl_tokens(text)
    words = [t[0].strip("[]").casefold() for t in tokens]
    creates = [i for i, word in enumerate(words) if word == "create"]
    require(len(creates) == 1, "Genau eine CREATE-Deklaration erforderlich")
    i = creates[0] + 1
    if words[i:i + 2] == ["or", "alter"]:
        i += 2
    m = skill.metadata
    require(words[i:i + 5] == ["function", m["schema_name"].casefold(), ".",
                               m["object_name"].casefold(), "("], "DDL-/Skillidentität")
    anchors = [j for j in range(i + 5, len(words) - 4)
               if words[j:j + 5] == ["returns", "table", "as", "return", "("]]
    require(len(anchors) == 1, "Nur explizite RETURNS TABLE AS RETURN Inline-TVF unterstützt")
    end = tokens[anchors[0] + 2][2]
    require(text[end:end + 1] == "\n", "AS muss für die Projektion mit LF abschließen")
    return text[:end + 1] + comment + text[end + 1:]


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
