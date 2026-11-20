---
name: "toolbelt-toolbelt-toolbelt-json-usp-validatejsonschema"
description: "Prüft JSON im begrenzten Profil toolbelt-2020-12-v1 mit exakten Zahlen, Unicode und globalem Arbeitsbudget; SUMMARY plus begrenzte Diagnosen."
skill_format_version: "1.0"
module_id: "toolbelt.json.schema"
schema_name: "toolbelt_json"
object_name: "USP_ValidateJsonSchema"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Json", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Vollständiger JSON-Wert (Objekt, Array oder Skalar), maximal MaxDocumentBytes UTF-16-Bytes. Leerer/fehlerhafter Text ergibt INVALID_JSON; doppelte Keys sind ungültig und ungepaarte Surrogate UNSUPPORTED. NULL (Default) in Json oder Schema ergibt SQL_NULL nach Argumentprüfung. Keine Typkonvertierung oder Änderung des Dokuments."}, {"name": "@Schema", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Boolean-Schema true/false oder Schemaobjekt des Profils toolbelt-2020-12-v1, maximal MaxSchemaBytes UTF-16-Bytes. Unterstützte Formen/Keywordtypen siehe JSON_SCHEMA_CONTRACT.md, Abschnitt Sichtbarer Profilumfang: $schema nur Draft2020-12; $defs, nichtrekursive lokale $ref, type, required, properties, additionalProperties, items, prefixItems, minItems/maxItems, minProperties/maxProperties, minLength/maxLength, minimum/maximum/exclusiveMinimum/exclusiveMaximum sowie title/description/$comment. Keine externen Referenzen, Zyklen, format, pattern, enum/const, Kombinatoren oder unbekannten Keywords. Alle Schemaorte einschließlich ungenutzter Definitionen werden vor der Instanz geprüft; NULL ergibt SQL_NULL nach Argumentprüfung."}, {"name": "@Profile", "sql_type": "varchar(32)", "sql_default": "'toolbelt-2020-12-v1'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Einziger erlaubter Wert, exakt ASCII und längensensitiv: toolbelt-2020-12-v1 (Default) wählt die dokumentierte begrenzte Draft2020-12-Teilmenge. Kein Trim/Casefold; NULL/leer/andere Werte werfen 55600/1. Keine Behauptung vollständiger Draftkonformität."}, {"name": "@MaxDocumentBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216 UTF-16-Bytes, Default 16777216; NULL/außerhalb wirft 55600/1, Dokumentüberschreitung liefert LIMIT/DOCUMENT_BYTES."}, {"name": "@MaxSchemaBytes", "sql_type": "bigint", "sql_default": "1048576", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1048576 UTF-16-Bytes, Default 1048576; NULL/außerhalb wirft 55600/1, Schemaüberschreitung liefert LIMIT/SCHEMA_BYTES."}, {"name": "@MaxDepth", "sql_type": "int", "sql_default": "128", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..128 offene Container in Dokument und Schema, Default 128; NULL/außerhalb wirft 55600/1. Parser beendet eine Überschreitung als LIMIT, nicht als gültiges Boolurteil."}, {"name": "@MaxEvaluationSteps", "sql_type": "bigint", "sql_default": "1000000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1000000 abstrakte Arbeitseinheiten über sämtliche Prüfphasen, Default 1000000; NULL/außerhalb wirft 55600/1. Keine Millisekunden-/CPUzeitangabe; Erschöpfung ergibt LIMIT/IsValid=NULL."}, {"name": "@MaxErrors", "sql_type": "int", "sql_default": "100", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 0..100 Diagnosezeilen, Default 100; 0 unterdrückt ERROR-Zeilen, SUMMARY bleibt. NULL/außerhalb wirft 55600/1. Begrenzt nur die Diagnose, nicht die vollständige Evaluation; ErrorsTruncated weist Kürzung aus."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Nur payloadfreie Messages; keine Dokument-/Schema-/Endpointausgabe."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.json.schema/Source/USP_ValidateJsonSchema.sql"]
review_status: "draft"
source_module_version: "1.0.1"
---

# USP_ValidateJsonSchema

## Zweck und Einsatzfälle

Prüft JSON im begrenzten Profil toolbelt-2020-12-v1 mit exakten Zahlen, Unicode und globalem Arbeitsbudget; SUMMARY plus begrenzte Diagnosen.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- SQL Server2019+ und CL150+, bekannte SAFE-Core-/Schema-Assemblies in derselben Datenbank, ResultTable >=1.0.0, vorhandene Aufrufrechte. Nur Teilqualifikation, unreleased.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `NULL` | Input | Vollständiger JSON-Wert (Objekt, Array oder Skalar), maximal MaxDocumentBytes UTF-16-Bytes. Leerer/fehlerhafter Text ergibt INVALID_JSON; doppelte Keys sind ungültig und ungepaarte Surrogate UNSUPPORTED. NULL (Default) in Json oder Schema ergibt SQL_NULL nach Argumentprüfung. Keine Typkonvertierung oder Änderung des Dokuments. |
| `@Schema` | `nvarchar(max)` | `NULL` | Input | Boolean-Schema true/false oder Schemaobjekt des Profils toolbelt-2020-12-v1, maximal MaxSchemaBytes UTF-16-Bytes. Unterstützte Formen/Keywordtypen siehe JSON_SCHEMA_CONTRACT.md, Abschnitt Sichtbarer Profilumfang: $schema nur Draft2020-12; $defs, nichtrekursive lokale $ref, type, required, properties, additionalProperties, items, prefixItems, minItems/maxItems, minProperties/maxProperties, minLength/maxLength, minimum/maximum/exclusiveMinimum/exclusiveMaximum sowie title/description/$comment. Keine externen Referenzen, Zyklen, format, pattern, enum/const, Kombinatoren oder unbekannten Keywords. Alle Schemaorte einschließlich ungenutzter Definitionen werden vor der Instanz geprüft; NULL ergibt SQL_NULL nach Argumentprüfung. |
| `@Profile` | `varchar(32)` | `'toolbelt-2020-12-v1'` | Input | Einziger erlaubter Wert, exakt ASCII und längensensitiv: toolbelt-2020-12-v1 (Default) wählt die dokumentierte begrenzte Draft2020-12-Teilmenge. Kein Trim/Casefold; NULL/leer/andere Werte werfen 55600/1. Keine Behauptung vollständiger Draftkonformität. |
| `@MaxDocumentBytes` | `bigint` | `16777216` | Input | Ganzzahl 1..16777216 UTF-16-Bytes, Default 16777216; NULL/außerhalb wirft 55600/1, Dokumentüberschreitung liefert LIMIT/DOCUMENT_BYTES. |
| `@MaxSchemaBytes` | `bigint` | `1048576` | Input | Ganzzahl 1..1048576 UTF-16-Bytes, Default 1048576; NULL/außerhalb wirft 55600/1, Schemaüberschreitung liefert LIMIT/SCHEMA_BYTES. |
| `@MaxDepth` | `int` | `128` | Input | Ganzzahl 1..128 offene Container in Dokument und Schema, Default 128; NULL/außerhalb wirft 55600/1. Parser beendet eine Überschreitung als LIMIT, nicht als gültiges Boolurteil. |
| `@MaxEvaluationSteps` | `bigint` | `1000000` | Input | Ganzzahl 1..1000000 abstrakte Arbeitseinheiten über sämtliche Prüfphasen, Default 1000000; NULL/außerhalb wirft 55600/1. Keine Millisekunden-/CPUzeitangabe; Erschöpfung ergibt LIMIT/IsValid=NULL. |
| `@MaxErrors` | `int` | `100` | Input | Ganzzahl 0..100 Diagnosezeilen, Default 100; 0 unterdrückt ERROR-Zeilen, SUMMARY bleibt. NULL/außerhalb wirft 55600/1. Begrenzt nur die Diagnose, nicht die vollständige Evaluation; ErrorsTruncated weist Kürzung aus. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Nur payloadfreie Messages; keine Dokument-/Schema-/Endpointausgabe. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

SUMMARY oder ERROR.

SUMMARY=0, ERROR=1..N; explizite Ergebnisordnung.

VALID/INVALID_INSTANCE/INVALID_SCHEMA/INVALID_JSON/UNSUPPORTED/SQL_NULL/LIMIT.

Exaktes angewandtes Profil.

1 bei VALID, 0 bei vollständigem INVALID_INSTANCE; sonst NULL.

RFC6901-Ort in der Instanz; leer=root, NULL=unbekannt/nicht betroffen.

RFC6901-Ort im Schema; vollständige unveränderte decoded Keys.

Zuständiges Keyword; NULL wenn nicht bekannt oder länger als 128 Einheiten.

Kanonischer Fehlercode; VALID-SUMMARY ohne Code.

Unterdrückte Diagnosen; auf allen Zeilen gleicher Endzustand.

## Aufrufbeispiele

```sql
EXEC toolbelt_json.USP_ValidateJsonSchema @Json=N'{"quantity":3}', @Schema=N'{"properties":{"quantity":{"type":"integer","minimum":1}}}';
```

```sql
EXEC toolbelt_json.USP_ValidateJsonSchema @Hilfe=1;
```

## Rechte

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Ungültiges Profil oder Ressourcenargument.

Interner Transport-/Namespace-/Dependencyvertrag verletzt; kein Fachurteil.

## Aussagegrenzen

Kein volles Draft2020-12; lokale nichtrekursive Refs, exakte Zahlen/Unicode, kein externer Zugriff.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.json.schema/Documentation/USP_ValidateJsonSchema.md`

Keine Installations-, Definitions- oder Rechteattestation.
