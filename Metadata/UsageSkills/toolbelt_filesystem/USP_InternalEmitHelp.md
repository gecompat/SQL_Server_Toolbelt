---
name: "toolbelt-filesystem-internal-emit-help"
description: "Interner rein lesender Formatierer für die bisherige Dateisystem-Hilfe."
skill_format_version: "1.0"
module_id: "toolbelt.filesystem.windows"
schema_name: "toolbelt_filesystem"
object_name: "USP_InternalEmitHelp"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@ObjectName", "sql_type": "sysname", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Bezeichnung des vom Caller beschriebenen Objekts als sysname; nur Ausgabedatum, keine Auflösung oder Ausführung. Kein SQL-Default; NULL wird nicht vorab zurückgewiesen."}, {"name": "@Description", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Vom Caller gelieferter Beschreibungstext als nvarchar(max), nur Ausgabe; kein SQL-Default. NULL ist möglich, kein fachlicher Default."}, {"name": "@ExampleSql", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Vom Caller gelieferter SQL-Beispieltext als nvarchar(max); wird nur als Datenfeld ausgegeben, niemals ausgeführt. Kein SQL-Default; NULL ist möglich."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler abschließender bit, Default 0. 1 liefert ausschließlich den eigenen vollständigen Skill und kehrt vor Tabellen-/Datei-/CLR-Zugriff zurück. 0 oder NULL führt den bisherigen Helferpfad aus. Bisherige Pflichtargumente bleiben auch beim Hilfeaufruf syntaktisch erforderlich."}]
source_paths: ["Modules/toolbelt.filesystem.windows/Source/Procedures.sql"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_filesystem.USP_ReadBinaryFileChunk", "toolbelt_filesystem.USP_ListDirectory"]
---

# USP_InternalEmitHelp

## Zweck und Einsatzfälle

Interner rein lesender Formatierer für die bisherige Dateisystem-Hilfe. Internes Implementierungsdetail; Anwendungen verwenden die öffentlichen Dateisystem-Prozeduren mit deren vollständigem Autorisierungsvertrag.

## Voraussetzungen

Dateisystem-Modul unterstützt Windows SQL Server 2019/2022/2025. Dieser Helfer ist reines T-SQL; sein eigener @Hilfe=1-Pfad benötigt weder eine Ergebnistabelle noch Rootkonfiguration, Windowsimpersonation oder einen CLR-/Dateiaufruf. Der Normalpfad formatiert nur vom Caller gelieferte Metadaten.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@ObjectName` | `sysname` | `kein Default` | Bezeichnung des vom Caller beschriebenen Objekts als sysname; nur Ausgabedatum, keine Auflösung oder Ausführung. Kein SQL-Default; NULL wird nicht vorab zurückgewiesen. |
| `@Description` | `nvarchar(max)` | `kein Default` | Vom Caller gelieferter Beschreibungstext als nvarchar(max), nur Ausgabe; kein SQL-Default. NULL ist möglich, kein fachlicher Default. |
| `@ExampleSql` | `nvarchar(max)` | `kein Default` | Vom Caller gelieferter SQL-Beispieltext als nvarchar(max); wird nur als Datenfeld ausgegeben, niemals ausgeführt. Kein SQL-Default; NULL ist möglich. |
| `@Hilfe` | `bit` | `0` | Optionaler abschließender bit, Default 0. 1 liefert ausschließlich den eigenen vollständigen Skill und kehrt vor Tabellen-/Datei-/CLR-Zugriff zurück. 0 oder NULL führt den bisherigen Helferpfad aus. Bisherige Pflichtargumente bleiben auch beim Hilfeaufruf syntaktisch erforderlich. |

## Ergebnisse

Bei @Hilfe=1 genau eine konstante Skillzeile: SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max), RETURN 0. Normalpfad: bisheriges zwölfspaltiges Help-Resultset HelpContractVersion, SchemaName, ObjectName, Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue, Description, ExampleSql. Es enthält eine Beschreibung, fünf generische Steuerparameterzeilen und eine Einschränkungszeile; keine Behauptung vollständiger Parameterhilfe eines beliebigen Zielobjekts.

## Aufrufbeispiele

```sql
EXEC toolbelt_filesystem.USP_InternalEmitHelp @ObjectName=NULL,@Description=NULL,@ExampleSql=NULL,@Hilfe=1;
-- Nur der eigene Skill; keine Dateisystemoperation.
```

## Rechte

Vorhandene EXECUTE-Rechte im autorisierten Modulpfad, keine automatische Rechtevergabe. Normale Routingoperationen benötigen vorhandene Temp-Tabellen und die Rechte des ResultTable-Vertrags. Hilfe vergibt keine Rechte und ersetzt keine Windows-/Root-/ServiceAccount-Freigabe öffentlicher Dateioperationen.

## Ressourcenbedarf

Feste Anzahl von UNION-ALL-Hilfezeilen; Länge der Callerbeschreibung und des Beispieltexts ist nvarchar(max) und besitzt hier kein zusätzliches kleines Limit. Skillhilfe ist konstant, Unicode und ohne Runtime-Katalogabfrage.

## Nebenwirkungen

Keine DML-/Datei-/Netzwerk-/Konfigurationsänderung; normales Hilfeformatieren gibt ausschließlich Daten aus. Neuer Hilfezweig führt nichts davon aus und verändert keine OUTPUT-Werte.

## Fehlerbehandlung

Es gibt keine neuen fachlichen Fehlercodes. Fehlende Pflichtargumente, Objekt-/Ausführungsrechte, nicht vorhandene Caller-Temps und unerwartete Enginefehler bleiben Fehler. Beim Routing werden Fehler des ResultTable-Kerns unverändert weitergegeben; keine automatische Wiederholung oder Rechteausweitung.

## Aussagegrenzen

Interner Helfer, keine öffentliche Datei- oder Berechtigungs-API. Frei gelieferter Beschreibungstext attestiert weder Existenz noch Rechte oder Sicherheit eines Zielobjekts. ExampleSql bleibt Daten, nicht ein auszuführender Auftrag. Native Akzeptanz des neuen Hilfezweigs ist separat offen; historische Fachbelege gelten nur für den unveränderten Normalpfad.
