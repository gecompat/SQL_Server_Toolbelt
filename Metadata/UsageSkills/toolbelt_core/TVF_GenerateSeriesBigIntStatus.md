---
name: "toolbelt-toolbelt-toolbelt-core-tvf-generateseriesbigintstatus"
description: "Vor Expansion exakte Anzahl mit decimal(38,0) und Restrechnung bestimmen. Höchstens 1000000 OK-Zeilen. LIMIT, INVALID, SQL_NULL oder EMPTY liefern eine Kontrollzeile ohne Value. RequestedRows unterscheidet leere und zu große Reihen. Keine garantierte Reihenfolge. Die mathematischen Alt-APIs bleiben unverändert und benötigen vertrauenswürdige Direktgrants. Untrusted Legacygrants werden nicht automatisch entzogen; SC-018 bleibt in einer solchen Installation offen."
skill_format_version: "1.0"
module_id: "toolbelt.core.generate-series"
schema_name: "toolbelt_core"
object_name: "TVF_GenerateSeriesBigIntStatus"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Start", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Erster Wert im gesamten SQL-bigint-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt eine SQL_NULL-Kontrollzeile."}, {"name": "@Stop", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Inklusive Zielgrenze im SQL-bigint-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt SQL_NULL."}, {"name": "@Step", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Ganzzahlige Schrittweite als bigint. Default/NULL: +1 bei Start <= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben EMPTY. 0 ergibt INVALID; NULL bei Start/Stop hat Vorrang. Maximal 1000000 Werte, sonst LIMIT mit RequestedRows."}]
source_paths: ["Modules/toolbelt.core.generate-series/Source/TVF_GenerateSeriesBigInt.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# TVF_GenerateSeriesBigIntStatus

## Zweck und Einsatzfälle

Vor Expansion exakte Anzahl mit decimal(38,0) und Restrechnung bestimmen. Höchstens 1000000 OK-Zeilen. LIMIT, INVALID, SQL_NULL oder EMPTY liefern eine Kontrollzeile ohne Value. RequestedRows unterscheidet leere und zu große Reihen. Keine garantierte Reihenfolge. Die mathematischen Alt-APIs bleiben unverändert und benötigen vertrauenswürdige Direktgrants. Untrusted Legacygrants werden nicht automatisch entzogen; SC-018 bleibt in einer solchen Installation offen.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Start` | `bigint` | `kein Default` | Input | Erster Wert im gesamten SQL-bigint-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt eine SQL_NULL-Kontrollzeile. |
| `@Stop` | `bigint` | `kein Default` | Input | Inklusive Zielgrenze im SQL-bigint-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt SQL_NULL. |
| `@Step` | `bigint` | `NULL` | Input | Ganzzahlige Schrittweite als bigint. Default/NULL: +1 bei Start &lt;= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben EMPTY. 0 ergibt INVALID; NULL bei Start/Stop hat Vorrang. Maximal 1000000 Werte, sonst LIMIT mit RequestedRows. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_core.TVF_GenerateSeriesBigIntStatus(1,5,DEFAULT);
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
- `Modules/toolbelt.core.generate-series/Documentation/TVF_GenerateSeriesBigIntStatus.md`

Keine Installations-, Definitions- oder Rechteattestation.
