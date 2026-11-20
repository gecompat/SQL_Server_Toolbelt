---
name: "toolbelt-toolbelt-toolbelt-datetime-tvf-datespinemonth"
description: "Liefert alle Monate, die einen halboffenen Zeitraum schneiden."
skill_format_version: "1.0"
module_id: "toolbelt.datetime.date-spine"
schema_name: "toolbelt_datetime"
object_name: "TVF_DateSpineMonth"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@RangeStart", "sql_type": "date", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Inklusive Untergrenze; auch die diesen Tag enthaltende Periode wird ausgegeben. NULL oder Start >= Ende liefert keine Zeilen."}, {"name": "@RangeEndExclusive", "sql_type": "date", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Exklusive Obergrenze; ausgegeben werden nur Perioden, die [Start,Ende) schneiden. NULL, gleiche oder umgekehrte Grenzen liefern keine Zeilen. Kein unbegrenztes Ende und kein Datum jenseits 9999-12-31."}]
source_paths: ["Modules/toolbelt.datetime.date-spine/Source/TVF_DateSpineMonth.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# TVF_DateSpineMonth

## Zweck und Einsatzfälle

Liefert alle Monate, die einen halboffenen Zeitraum schneiden.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RangeStart` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Inklusive Untergrenze; auch die diesen Tag enthaltende Periode wird ausgegeben. NULL oder Start &gt;= Ende liefert keine Zeilen. |
| `@RangeEndExclusive` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Exklusive Obergrenze; ausgegeben werden nur Perioden, die [Start,Ende) schneiden. NULL, gleiche oder umgekehrte Grenzen liefern keine Zeilen. Kein unbegrenztes Ende und kein Datum jenseits 9999-12-31. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_datetime.TVF_DateSpineMonth(CONVERT(date,'2024-01-15'), CONVERT(date,'2024-03-01'));
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
- `Modules/toolbelt.datetime.date-spine/Documentation/TVF_DateSpineMonth.md`

Keine Installations-, Definitions- oder Rechteattestation.
