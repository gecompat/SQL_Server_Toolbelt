---
name: "toolbelt-metadata-object-usage-skills"
description: "Bekannte Toolbelt-Objekte und ihre vollständigen maschinenlesbaren Usage-Skills lesen."
skill_format_version: "1.0"
module_id: "toolbelt.metadata.capability-catalog"
schema_name: "toolbelt_metadata"
object_name: "VW_ObjectUsageSkills"
object_type: "VW"
database_role: "toolbelt"
is_internal: false
parameters: []
source_paths: ["Scripts/Metadata/usage_skills.py"]
review_status: "verified"
source_module_version: "1.0.0"
---

# VW_ObjectUsageSkills

## Zweck und Einsatzfälle

Zuerst anhand von Kurzbeschreibungen ein passendes bekanntes Objekt auswählen, anschließend dessen vollständigen Skill lesen und erst mit ausreichender Benutzerautorität und passenden Ziel-/Aufruferrechten einen Aufruf formulieren.

## Voraussetzungen

Neue Skill-Sicht im gewählten Ziel verfügbar und vorhandenes SELECT-Recht. Die Einträge sind konstante bekannte Beschreibungen und bestätigen weder Installation noch aktuelle Objektdefinition oder Ausführungsrechte. DatabaseRole bezeichnet eine logische Projektrolle, keinen fest kodierten Datenbanknamen.

## Parameter und Zugriff

Keine Parameter. Identität ist DatabaseRole, SchemaName und ObjectName. Für schemafreie Objekte ist SchemaName der leere Text; ObjectType unterscheidet ihre technische Art. IsInternal=1 bezeichnet interne Helfer; deren Skills nennen geeignete öffentliche Einstiege.

## Ergebnisse

Genau acht Spalten: SchemaName sysname, ObjectName sysname, ObjectType varchar(60), DatabaseRole nvarchar(128), IsInternal bit, Description nvarchar(4000), SkillFormatVersion varchar(16) und SkillMarkdown nvarchar(max). Eine Zeile je dokumentierter Identität. SkillMarkdown enthält den vollständigen UTF-8/LF-Quelltext als Unicodewert einschließlich YAML-Frontmatter; kein Hash- oder Definitionsattest.

## Aufrufbeispiele

```sql
SELECT SchemaName,ObjectName,ObjectType,DatabaseRole,IsInternal,Description
FROM toolbelt_metadata.VW_ObjectUsageSkills
ORDER BY DatabaseRole,SchemaName,ObjectName;

SELECT SkillMarkdown
FROM toolbelt_metadata.VW_ObjectUsageSkills
WHERE DatabaseRole=N'toolbelt'
  AND SchemaName=N'toolbelt_conversion'
  AND ObjectName=N'TVF_Base64Encode';
```

## Rechte

Vorhandenes SELECT auf der Sicht. Sie vergibt keine Rechte auf beschriebene Objekte und ersetzt keine Prüfung des tatsächlichen Aufrufkontexts. Kein automatisches GRANT oder EXECUTE AS.

## Ressourcenbedarf

Generierte Konstanten ohne Runtime-Katalog-/Fachdatenabfrage. Vollständige Skills können lang sein; zuerst Kurzbeschreibungen und danach einzelne SkillMarkdown-Werte lesen. Client-/Anzeigegrenzen dürfen nicht mit serverseitiger Kürzung verwechselt werden.

## Nebenwirkungen

Read-only; keine Analyse, keine Tabellen, Extended Properties, LLM-Aufrufe oder externen Dienste. Beschreibungen und Beispiele führen keine SQL-Anweisung selbstständig aus.

## Fehlerbehandlung

Fehlende Sicht oder SELECT-Rechte bleiben Enginefehler. Bei unbekannter Identität liefert der SELECT keine Zeile; dies beweist keine Nichtinstallation. Nicht unterstützte oder widersprüchliche Skillquellen brechen die Generierung vor der Ausgabe ab.

## Aussagegrenzen

Keine Aussage über installierte Version, Definition, Metadatensichtbarkeit anderer Objekte oder vorhandene Ausführungsrechte. Interne Objekte nicht als öffentliche API verwenden. Die aktuelle Implementierung befindet sich in der Prototypabnahme; vollständige Inventarabdeckung und native Integration sind separat nachzuweisen.
