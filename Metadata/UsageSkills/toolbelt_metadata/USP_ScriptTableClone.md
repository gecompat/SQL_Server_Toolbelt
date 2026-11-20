---
name: "toolbelt-toolbelt-toolbelt-metadata-usp-scripttableclone"
description: "Vollständige DDL-Vorschau innerhalb des begrenzten unterstützten Strukturumfangs; niemals DDL-Ausführung oder Datenkopie. Unsupported führt zum Abbruch."
skill_format_version: "1.0"
module_id: "toolbelt.metadata.table-clone"
schema_name: "toolbelt_metadata"
object_name: "USP_ScriptTableClone"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@SourceSchema", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": true, "description": "Schema der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung."}, {"name": "@SourceTable", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": true, "description": "Name der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung."}, {"name": "@TargetSchema", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": true, "description": "Vorhandenes Zielschema in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung."}, {"name": "@TargetTable", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": true, "description": "Name der geplanten neuen Zieltabelle, darf noch nicht existieren in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung."}, {"name": "@IncludeIdentity", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ im gebundenen bit: 0 lässt IDENTITY-Eigenschaft weg (Default); 1 übernimmt Seed/Increment der Definition, niemals aktuellen last_value oder Daten. NULL ist ungültig. Gilt gemeinsam für alle gemappten Tabellen."}, {"name": "@IncludeExtendedProperties", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ im gebundenen bit: 0 lehnt vorhandene relevante Extended Properties ab (Default), statt sie still zu ignorieren; 1 rendert die unterstützten originalen sql_variant-Werte samt Metadaten gemäß W1-Vertrag. Toolbelt.-Marker, FK-Properties und nicht unterstützte Propertytypen bleiben ausgeschlossen. NULL ungültig; keine Kopie von Rechten/Ownern."}, {"name": "@TableMap", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) wählt Einzelmodus mit vier expliziten Identifierparametern. Sonst Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Für Script/Execute darf der Name nach # nur ASCII-Buchstaben, Ziffern und _ enthalten; die vier Einzelidentifier müssen NULL sein. Gemappte FK-Referenzen werden auf ihre Ziele umgebogen."}, {"name": "@ExternalReferenceRule", "sql_type": "varchar(16)", "sql_default": "'REJECT'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ, bytegenau ohne Trim/Casefold: REJECT (Default) lehnt ausgehende FKs auf nicht gemappte Referenzziele ab; KEEP ist nur im Mapmodus erlaubt und erhält für diese Ziele den originalen qualifizierten Namen. Gemappte Referenzen werden in beiden Modi umgebogen; KEEP überspringt keinen FK. Im Einzelmodus ausschließlich REJECT. NULL/andere Werte ungültig."}, {"name": "@IncludeTriggers", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ im gebundenen bit: 0 lehnt vorhandene Trigger ab (Default); 1 rendert unterstützte gewöhnliche gemappte DML-Trigger im genehmigten Script-only-Pfad. Erfordert Windows SQL2019/2022/2025 und exakt vorhandene qualifizierte Parserbindung. Kein freies Rewrite beliebiger Trigger, keine Ausführung und keine automatische Parserinstallation. NULL ungültig."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht die Map-Tabelle."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 meldet den vollständig vorbereiteten Script-only-Plan; bei ResultTable zusätzlich kumulative Helperstufen. Kein Zusatzresultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.metadata.table-clone/Source/USP_ScriptTableClone.sql"]
review_status: "draft"
source_module_version: "4.1.1"
---

# USP_ScriptTableClone

## Zweck und Einsatzfälle

Vollständige DDL-Vorschau innerhalb des begrenzten unterstützten Strukturumfangs; niemals DDL-Ausführung oder Datenkopie. Unsupported führt zum Abbruch.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Vorhandene synthetische Quelltabelle und sichtbares Zielschema; Zielname darf noch nicht existieren. IncludeTriggers=1 verlangt Windows und den separat installierten Parser 2.0.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SourceSchema` | `nvarchar(max)` | `NULL` | Input | Schema der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@SourceTable` | `nvarchar(max)` | `NULL` | Input | Name der vorhandenen normalen Quelltabelle in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@TargetSchema` | `nvarchar(max)` | `NULL` | Input | Vorhandenes Zielschema in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@TargetTable` | `nvarchar(max)` | `NULL` | Input | Name der geplanten neuen Zieltabelle, darf noch nicht existieren in der Installationsdatenbank. Einzelner Identifierwert mit 1..128 UTF-16-Einheiten, ohne NUL, kein Multipartname/Trim; Quotierung übernimmt die API. Im Einzelmodus TableMap=NULL fachlich erforderlich, im Mapmodus ausschließlich NULL. Default NULL aktiviert keine automatische Namensableitung. |
| `@IncludeIdentity` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lässt IDENTITY-Eigenschaft weg (Default); 1 übernimmt Seed/Increment der Definition, niemals aktuellen last_value oder Daten. NULL ist ungültig. Gilt gemeinsam für alle gemappten Tabellen. |
| `@IncludeExtendedProperties` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt vorhandene relevante Extended Properties ab (Default), statt sie still zu ignorieren; 1 rendert die unterstützten originalen sql_variant-Werte samt Metadaten gemäß W1-Vertrag. Toolbelt.-Marker, FK-Properties und nicht unterstützte Propertytypen bleiben ausgeschlossen. NULL ungültig; keine Kopie von Rechten/Ownern. |
| `@TableMap` | `sysname` | `NULL` | Input | NULL (Default) wählt Einzelmodus mit vier expliziten Identifierparametern. Sonst Vorhandene caller-lokale #Temp mit genau fünf NOT-NULL-Basisspalten: MapOrdinal int, SourceSchema nvarchar(max), SourceTable nvarchar(max), TargetSchema nvarchar(max), TargetTable nvarchar(max); keine Alias-/computed-/Zusatzspalten. 1..64 Zeilen, positive eindeutige MapOrdinal-Werte. Vier einzelne unquotierte Identifierwerte je Zeile, 1..128 UTF-16-Einheiten ohne NUL, keine Multipartinterpretation/Trim. Source-/Target-Identitäten müssen jeweils eindeutig sein. Kein #tbx_-Präfix und keine Identität mit ResultTable. Für Script/Execute darf der Name nach # nur ASCII-Buchstaben, Ziffern und _ enthalten; die vier Einzelidentifier müssen NULL sein. Gemappte FK-Referenzen werden auf ihre Ziele umgebogen. |
| `@ExternalReferenceRule` | `varchar(16)` | `'REJECT'` | Input | Taxativ, bytegenau ohne Trim/Casefold: REJECT (Default) lehnt ausgehende FKs auf nicht gemappte Referenzziele ab; KEEP ist nur im Mapmodus erlaubt und erhält für diese Ziele den originalen qualifizierten Namen. Gemappte Referenzen werden in beiden Modi umgebogen; KEEP überspringt keinen FK. Im Einzelmodus ausschließlich REJECT. NULL/andere Werte ungültig. |
| `@IncludeTriggers` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 lehnt vorhandene Trigger ab (Default); 1 rendert unterstützte gewöhnliche gemappte DML-Trigger im genehmigten Script-only-Pfad. Erfordert Windows SQL2019/2022/2025 und exakt vorhandene qualifizierte Parserbindung. Kein freies Rewrite beliebiger Trigger, keine Ausführung und keine automatische Parserinstallation. NULL ungültig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix und nicht die Map-Tabelle. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wirkt wie 0. 0 keine eigenen Messages, 1..255 meldet den vollständig vorbereiteten Script-only-Plan; bei ResultTable zusätzlich kumulative Helperstufen. Kein Zusatzresultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

1-basiert lückenlos; Ausführung ausschließlich außerhalb dieser API.

SESSION_OPTION, TABLE, DEFAULT, CHECK, PRIMARY_KEY, UNIQUE_CONSTRAINT, INDEX, EXTENDED_PROPERTY, FOREIGN_KEY, FOREIGN_KEY_STATE sowie beim Trigger-Opt-in TRIGGER und TRIGGER_STATE.

Gequoteter Zielname; Indexnamen mit Zieltabellenqualifier.

Eine Anweisung; EXTENDED_PROPERTY ist ein typisierter DECLARE-plus-EXEC-Batch, TRIGGER ein fester Quell-SET-plus-sp_executesql-Batch mit innerem CREATE zuerst. Sieben SET-Zeilen zuerst; Latin1_General_100_BIN2.

## Aufrufbeispiele

```sql
EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N'dbo',@SourceTable=N'SyntheticSource',@TargetSchema=N'dbo',@TargetTable=N'SyntheticClone';
```

```sql
EXEC toolbelt_metadata.USP_ScriptTableClone @SourceSchema=N'dbo',@SourceTable=N'SyntheticSource',@TargetSchema=N'dbo',@TargetTable=N'SyntheticClone',@IncludeTriggers=1;
```

## Rechte

EXECUTE plus datenbankweite VIEW DEFINITION für vollständige FK-/Kollisionssicht; Computed und Trigger-Opt-in zusätzlich vorhandenes SELECT sys.sql_expression_dependencies. Trigger-Opt-in verlangt vollständige Assembly-/Binding-Sicht und SELECT auf vier Parser-TVFs. ResultTable zusätzlich Helper-EXECUTE. Keine Rechteausweitung.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

53900 Argumente,53901 Quelle/Sichtbarkeit,53902 Ziel/Sichtbarkeit,53903 Unsupported,53904 Namekollision,53905 Definitionen,53906 Ressourcen,53907 Dependency,53908 Namespace.

## Aussagegrenzen

Computed/PERSISTED und Filter unterstützt; W1 ohne FK, W2 mit begrenzten FK-Zuständen. Trigger-Opt-in ohne dynamischen Body, EXECUTE AS, CLR, Verschlüsselung oder externe/unklare Referenzen; kein Kopieren von Funktionen/Prozeduren. Quelle während Planung strukturell stabil halten. Kein späterer Drift-/Kapazitätsnachweis.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.metadata.table-clone/Documentation/USP_ScriptTableClone.md`

Keine Installations-, Definitions- oder Rechteattestation.
