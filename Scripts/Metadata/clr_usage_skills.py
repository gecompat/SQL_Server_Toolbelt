"""Geprüfte Prozedur-Skills als CLR-Konstanten ohne Runtime-Dateizugriff erzeugen."""
from __future__ import annotations

import json
import re
from pathlib import Path

import usage_skills


def csharp_string(value: str):
    # JSON escape sequences are also valid ordinary C# string escapes. Escape
    # all Unicode so checkout line endings/source encodings cannot modify LF
    # inside a verbatim string or split supplementary characters in transport.
    return json.dumps(value, ensure_ascii=True)


def render(records, namespace="Toolbelt.Metadata", class_name="UsageSkillsGenerated"):
    usage_skills.require(re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*", namespace),
                         "CLR-Namespace")
    usage_skills.require(re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", class_name), "CLR-Klassenname")
    records = tuple(records)
    usage_skills.require(records, "Leere CLR-Skillmenge")
    cases, seen = [], set()
    for skill in sorted(records, key=lambda s: s.identity):
        usage_skills.validate(skill)
        m = skill.metadata
        usage_skills.require(m["object_type"] in ("USP", "CLR_USP"), "CLR-Hilfe benötigt Prozedur-Skills")
        usage_skills.require(m["database_role"] == "toolbelt", "Unbekannte CLR-Datenbankrolle")
        key = m["schema_name"] + "." + m["object_name"]
        usage_skills.require(key.casefold() not in seen, "Doppelte CLR-Skillidentität")
        seen.add(key.casefold())
        cases.append("                case " + csharp_string(key) + ":\n"
                     + "                    markdown = " + csharp_string(skill.markdown) + ";\n"
                     + "                    break;")
    return """// Automatisch aus kanonischen geprüften Usage-Skills erzeugt.
// Keine Runtime-Datei-, Katalog-, Netzwerk- oder LLM-Abhängigkeit.
using System;
using System.Data;
using Microsoft.SqlServer.Server;

namespace """ + namespace + """
{
    internal static class """ + class_name + """
    {
        // Diese Factory ist ohne SQL-Kontext prüfbar. Nur Send benutzt die
        // bestehende SQL-CLR-Pipe; sie führt keine Fachoperation aus.
        internal static SqlDataRecord CreateRecord(string schemaName, string objectName)
        {
            string markdown;
            switch (schemaName + "." + objectName)
            {
""" + "\n".join(cases) + """
                default:
                    throw new ArgumentException("USAGE_SKILL_UNKNOWN_OBJECT");
            }
            SqlDataRecord row = new SqlDataRecord(
                new SqlMetaData("SkillFormatVersion", SqlDbType.VarChar, 16),
                new SqlMetaData("SchemaName", SqlDbType.NVarChar, 128),
                new SqlMetaData("ObjectName", SqlDbType.NVarChar, 128),
                new SqlMetaData("SkillMarkdown", SqlDbType.NVarChar, SqlMetaData.Max));
            row.SetString(0, """ + csharp_string(usage_skills.FORMAT_VERSION) + """);
            row.SetString(1, schemaName);
            row.SetString(2, objectName);
            row.SetString(3, markdown);
            return row;
        }

        internal static void Send(string schemaName, string objectName)
        {
            SqlContext.Pipe.Send(CreateRecord(schemaName, objectName));
        }
    }
}
"""


def module_records(root: Path, module_id: str):
    """Nur eine vollständig geprüfte Modulmenge in eine neue Datei schreiben."""
    expected = {key: value for key, value in usage_skills.inventory(root).items()
                if value["module_id"] == module_id and value["object_type"] == "CLR_USP"}
    usage_skills.require(expected, "Modul besitzt keine deklarierten CLR-Prozeduren")
    records = []
    for _, schema, name in sorted(expected):
        path = usage_skills.source_file(root, schema, name)
        usage_skills.require(path.is_file(), "CLR-Prozedur-Skillquelle fehlt: " + schema + "." + name)
        records.append(usage_skills.read(path))
    usage_skills.validate_coverage(records, expected)
    return records


def generate(root: Path, module_id: str, namespace: str, output: Path, *, check=False):
    records = module_records(root, module_id)
    text = render(records, namespace)
    if check:
        usage_skills.require(output.is_file() and output.read_bytes() == text.encode("utf-8"),
                             "CLR-Skillprojektion ist nicht kanonisch")
        return len(records)
    usage_skills.require(not output.exists(), "Neue CLR-Ausgabedatei erforderlich")
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("x", encoding="utf-8", newline="\n") as stream:
        stream.write(text)
    return len(records)


PROVIDER_PARAMETER = ", SqlBoolean hilfe = default(SqlBoolean)"


def provider_guard(skill):
    usage_skills.validate(skill)
    m = skill.metadata
    usage_skills.require(m["object_type"] == "CLR_USP" and m["object_name"].startswith("CLR_"),
                         "CLR-Provideridentität")
    p = m["parameters"][-1]
    usage_skills.require(p["name"] == "@Hilfe" and p["sql_type"] == "bit" and p["sql_default"] == "0",
                         "Optionaler CLR-Hilfeschalter erforderlich")
    return ('\n            if (hilfe.IsTrue) { UsageSkillsGenerated.Send('
            + csharp_string(m["schema_name"]) + ', ' + csharp_string(m["object_name"]) + '); return; }\n')


def project_provider_help(text, records):
    """Exakte zusätzliche Signatur/erste Anweisung; restliche Bytes erhalten."""
    for skill in records:
        method = skill.metadata["object_name"].removeprefix("CLR_")
        pattern = r"public static void " + re.escape(method) + r"\(([^\n]*?)\)(\s*\{)"
        found = list(re.finditer(pattern, text))
        usage_skills.require(len(found) == 1, "Eindeutige CLR-Providermethode")
        match = found[0]
        guard = provider_guard(skill)
        if PROVIDER_PARAMETER in match[1]:
            usage_skills.require(match[1].endswith(PROVIDER_PARAMETER)
                                 and text[match.end():].startswith(guard), "Nicht kanonische CLR-Hilfe")
            continue
        usage_skills.require("hilfe" not in match[1].casefold(), "Vorhandener CLR-Hilfeschalter")
        text = (text[:match.start(1)] + match[1] + PROVIDER_PARAMETER + ")" + match[2]
                + guard + text[match.end():])
    return text


def strip_provider_help(text, records):
    for skill in records:
        method = skill.metadata["object_name"].removeprefix("CLR_")
        pattern = r"public static void " + re.escape(method) + r"\(([^\n]*?)\)(\s*\{)"
        found = list(re.finditer(pattern, text))
        usage_skills.require(len(found) == 1, "Eindeutige CLR-Providermethode")
        match = found[0]
        guard = provider_guard(skill)
        usage_skills.require(match[1].endswith(PROVIDER_PARAMETER)
                             and text[match.end():].startswith(guard), "Nicht kanonische CLR-Hilfe")
        text = (text[:match.start(1)] + match[1][:-len(PROVIDER_PARAMETER)] + ")" + match[2]
                + text[match.end() + len(guard):])
    return text


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--module", required=True)
    parser.add_argument("--namespace", default="Toolbelt.Metadata")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    print("CLR_SKILL_PROJECTION objects=" + str(generate(Path(__file__).resolve().parents[2], args.module,
          args.namespace, args.output, check=args.check)) + "; SQL_NOT_EXECUTED")
