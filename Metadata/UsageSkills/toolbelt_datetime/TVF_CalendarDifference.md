---
name: "toolbelt-toolbelt-toolbelt-datetime-tvf-calendardifference"
description: "Zerlegt ein Datumsintervall nach der Anniversary-Regel in Kalenderjahre, Monate und Tage."
skill_format_version: "1.0"
module_id: "toolbelt.datetime.calendar-difference"
schema_name: "toolbelt_datetime"
object_name: "TVF_CalendarDifference"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@StartDate", "sql_type": "date", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Anfang des Vergleichs. Beide Reihenfolgen und gleiche Daten sind zulässig; die Richtung steht nur in Sign. NULL ergibt NULL in allen Ergebnisspalten."}, {"name": "@EndDate", "sql_type": "date", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Zweites Datum. Vollständige Jahre/Monate folgen der Anniversary-Regel einschließlich Monatsendklammerung. NULL ergibt NULL in allen Ergebnisspalten."}]
source_paths: ["Modules/toolbelt.datetime.calendar-difference/Source/TVF_CalendarDifference.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# TVF_CalendarDifference

## Zweck und Einsatzfälle

Zerlegt ein Datumsintervall nach der Anniversary-Regel in Kalenderjahre, Monate und Tage.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@StartDate` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Anfang des Vergleichs. Beide Reihenfolgen und gleiche Daten sind zulässig; die Richtung steht nur in Sign. NULL ergibt NULL in allen Ergebnisspalten. |
| `@EndDate` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Zweites Datum. Vollständige Jahre/Monate folgen der Anniversary-Regel einschließlich Monatsendklammerung. NULL ergibt NULL in allen Ergebnisspalten. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_datetime.TVF_CalendarDifference(CONVERT(date,'2024-01-31'), CONVERT(date,'2025-03-02'));
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
- `Modules/toolbelt.datetime.calendar-difference/Documentation/TVF_CalendarDifference.md`

Keine Installations-, Definitions- oder Rechteattestation.
