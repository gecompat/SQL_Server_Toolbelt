---
name: "toolbelt-toolbelt-toolbelt-core-tvf-generateseriesbigint"
description: "Erzeugt eine Folge von bigint-Werten einschließlich erreichbarem Endwert."
skill_format_version: "1.0"
module_id: "toolbelt.core.generate-series"
schema_name: "toolbelt_core"
object_name: "TVF_GenerateSeriesBigInt"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Start", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Erster Wert im gesamten SQL-bigint-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt keine Zeilen; ein zusätzlich übergebener Schritt 0 bleibt ein Enginefehler."}, {"name": "@Stop", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Inklusive Zielgrenze im SQL-bigint-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt keine Zeilen, außer dem ausdrücklich ungültigen Schritt-0-Fall."}, {"name": "@Step", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Ganzzahlige Schrittweite als bigint. Default/NULL: +1 bei Start <= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben keine Zeilen. 0 ergibt einen SQL-Engine-Divisionsfehler.Die berechnete Zeilenzahl muss in bigint passen; keine feste kleine Ausgabelimitierung."}]
source_paths: ["Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesBigInt.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# TVF_GenerateSeriesBigInt

## Zweck und Einsatzfälle

Erzeugt eine Folge von bigint-Werten einschließlich erreichbarem Endwert.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Start` | `bigint` | `kein Default` | Input | Erster Wert im gesamten SQL-bigint-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt keine Zeilen; ein zusätzlich übergebener Schritt 0 bleibt ein Enginefehler. |
| `@Stop` | `bigint` | `kein Default` | Input | Inklusive Zielgrenze im SQL-bigint-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt keine Zeilen, außer dem ausdrücklich ungültigen Schritt-0-Fall. |
| `@Step` | `bigint` | `NULL` | Input | Ganzzahlige Schrittweite als bigint. Default/NULL: +1 bei Start &lt;= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben keine Zeilen. 0 ergibt einen SQL-Engine-Divisionsfehler.Die berechnete Zeilenzahl muss in bigint passen; keine feste kleine Ausgabelimitierung. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_core.TVF_GenerateSeriesBigInt(1, 5, 1);
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
- `Modules/toolbelt.core.generate-series/Documentation/TVF_GenerateSeriesBigInt.md`

Keine Installations-, Definitions- oder Rechteattestation.
