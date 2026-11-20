---
name: "toolbelt-toolbelt-toolbelt-json-tvf-jsonpathexistsstatus"
description: "Genau eine Zeile: FOUND/1, MISSING/0, INVALID/0, SQL_NULL/NULL oder LIMIT/NULL. Höchstens 10000 Frontierwerte; maximal 10001 werden zur Überschreitungsfeststellung aufgenommen. Vor jedem OPENJSON werden die vorgesehenen Inputbytes gegen das kumulative 64-MiB-Budget gebucht. Containerroots werden ohne zusätzliche Wrapper-Ebene validiert. Die bisherige TVF liefert bei LIMIT NULL; kein falsches MISSING."
skill_format_version: "1.0"
module_id: "toolbelt.json.path-exists"
schema_name: "toolbelt_json"
object_name: "TVF_JsonPathExistsStatus"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Json", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Vollständiger JSON-Wert einschließlich Skalar/root-null, maximal 16777216 UTF-16-Bytes und lexikalische Containertiefe 128. Leer ist ungültiges JSON. NULL in Json oder Path liefert SQL_NULL/NULL vor weiterer Prüfung. Syntaxfehler ergeben INVALID/0; Ressourcenüberschreitungen LIMIT/NULL im Statuskern beziehungsweise NULL in der Wertfassade. Frontier höchstens 10000 Werte, kumulatives Parserworkbudget 67108864 Bytes."}, {"name": "@Path", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "SQL/JSON-Teilmenge, maximal 4000 UTF-16-Einheiten/128 Segmente: $ für Root, .ASCII_key mit Buchstaben/Ziffern/_, .\"JSON-escaped key\" für beliebige Keys, [0].. mit nullbasiertem ASCII-Dezimalindex ohne führende Nullen, [*] für beliebiges Arrayelement. Keine Objektwildcards, Filter, Ranges, Indexlisten oder last. Optionale Präfixe lax / strict werden case-insensitiv erkannt und ändern den Existenzvertrag nicht; äußere normale Spaces werden entfernt. Keys bleiben binär/case-sensitiv. Leer/fehlerhaft ergibt INVALID/0; NULL ergibt SQL_NULL/NULL."}]
source_paths: ["Modules/toolbelt.json.path-exists/Source/TVF_JsonPathExists.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# TVF_JsonPathExistsStatus

## Zweck und Einsatzfälle

Genau eine Zeile: FOUND/1, MISSING/0, INVALID/0, SQL_NULL/NULL oder LIMIT/NULL. Höchstens 10000 Frontierwerte; maximal 10001 werden zur Überschreitungsfeststellung aufgenommen. Vor jedem OPENJSON werden die vorgesehenen Inputbytes gegen das kumulative 64-MiB-Budget gebucht. Containerroots werden ohne zusätzliche Wrapper-Ebene validiert. Die bisherige TVF liefert bei LIMIT NULL; kein falsches MISSING.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Json` | `nvarchar(max)` | `kein Default` | Input | Vollständiger JSON-Wert einschließlich Skalar/root-null, maximal 16777216 UTF-16-Bytes und lexikalische Containertiefe 128. Leer ist ungültiges JSON. NULL in Json oder Path liefert SQL_NULL/NULL vor weiterer Prüfung. Syntaxfehler ergeben INVALID/0; Ressourcenüberschreitungen LIMIT/NULL im Statuskern beziehungsweise NULL in der Wertfassade. Frontier höchstens 10000 Werte, kumulatives Parserworkbudget 67108864 Bytes. |
| `@Path` | `nvarchar(max)` | `kein Default` | Input | SQL/JSON-Teilmenge, maximal 4000 UTF-16-Einheiten/128 Segmente: $ für Root, .ASCII_key mit Buchstaben/Ziffern/_, ."JSON-escaped key" für beliebige Keys, [0].. mit nullbasiertem ASCII-Dezimalindex ohne führende Nullen, [*] für beliebiges Arrayelement. Keine Objektwildcards, Filter, Ranges, Indexlisten oder last. Optionale Präfixe lax / strict werden case-insensitiv erkannt und ändern den Existenzvertrag nicht; äußere normale Spaces werden entfernt. Keys bleiben binär/case-sensitiv. Leer/fehlerhaft ergibt INVALID/0; NULL ergibt SQL_NULL/NULL. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_json.TVF_JsonPathExistsStatus(N'{"a":null}',N'$.a');
```

## Rechte

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aussagegrenzen

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.json.path-exists/Documentation/TVF_JsonPathExistsStatus.md`

Keine Installations-, Definitions- oder Rechteattestation.
