---
name: "toolbelt-toolbelt-toolbelt-conversion-tvf-trycastdecimal"
description: "Prüft exakten decimal(38,18)-Bereich vor Skalenverlust; rundet niemals still."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.safe-cast"
schema_name: "toolbelt_conversion"
object_name: "TVF_TryCastDecimal"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Text", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "ASCII-Dezimaltext mit optional führendem +/-, mindestens einer Ganzzahlziffer und optional Punkt mit mindestens einer Nachkommastelle. Keine Kommas, Exponenten oder Spaces. Führende Nullen sind zulässig. Ziel decimal(38,18), maximal 20 Ganzzahl- und 18 relevante Nachkommastellen; weitere Nullen sind exakt entfernbar, weitere nichtnull Ziffern bedeuten LOSSY/SCALE. Ein Bereichsfehler hat davor Vorrang. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen."}, {"name": "@MaxInputBytes", "sql_type": "int", "sql_default": "8192", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/>8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT."}]
source_paths: ["Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastDecimal.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# TVF_TryCastDecimal

## Zweck und Einsatzfälle

Prüft exakten decimal(38,18)-Bereich vor Skalenverlust; rundet niemals still.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Vorhandenes SELECT; Bereichsüberschreitung ist OUT_OF_RANGE, sonst nichtnull Fractionrest LOSSY.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | ASCII-Dezimaltext mit optional führendem +/-, mindestens einer Ganzzahlziffer und optional Punkt mit mindestens einer Nachkommastelle. Keine Kommas, Exponenten oder Spaces. Führende Nullen sind zulässig. Ziel decimal(38,18), maximal 20 Ganzzahl- und 18 relevante Nachkommastellen; weitere Nullen sind exakt entfernbar, weitere nichtnull Ziffern bedeuten LOSSY/SCALE. Ein Bereichsfehler hat davor Vorrang. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/&gt;8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_conversion.TVF_TryCastDecimal(N'99999999999999999999.9999999999999999991', DEFAULT);
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
- `Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastDecimal.md`

Keine Installations-, Definitions- oder Rechteattestation.
