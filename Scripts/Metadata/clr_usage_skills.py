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


def generate(root: Path, module_id: str, namespace: str, output: Path):
    """Nur eine vollständig geprüfte Modulmenge in eine neue Datei schreiben."""
    expected = {key: value for key, value in usage_skills.inventory(root).items()
                if value["module_id"] == module_id and value["object_type"] == "CLR_USP"}
    usage_skills.require(expected, "Modul besitzt keine deklarierten CLR-Prozeduren")
    records = []
    for _, schema, name in sorted(expected):
        path = usage_skills.source_file(root, schema, name)
        usage_skills.require(path.is_file(), "CLR-Prozedur-Skillquelle fehlt: " + schema + "." + name)
        records.append(usage_skills.read(path))
    count = usage_skills.validate_coverage(records, expected)
    text = render(records, namespace)
    usage_skills.require(not output.exists(), "Neue CLR-Ausgabedatei erforderlich")
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("x", encoding="utf-8", newline="\n") as stream:
        stream.write(text)
    return count
