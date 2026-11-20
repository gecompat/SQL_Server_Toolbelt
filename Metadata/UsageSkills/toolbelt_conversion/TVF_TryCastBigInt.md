---
name: "toolbelt-toolbelt-toolbelt-conversion-tvf-trycastbigint"
description: "Prüft ASCII-Ganzzahltext und den exakten bigint-Bereich; liefert Value, Status und ErrorCode."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.safe-cast"
schema_name: "toolbelt_conversion"
object_name: "TVF_TryCastBigInt"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Text", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "ASCII-Dezimaltext mit mindestens einer Ziffer 0..9 und optional einem führenden + oder -. Führende Nullen/negative Null sind zulässig. Kein Trim, kein Unicode-Ziffernersatz, Dezimalpunkt, Exponent oder Tausendertrennzeichen. Zielbereich -9223372036854775808..9223372036854775807. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen."}, {"name": "@MaxInputBytes", "sql_type": "int", "sql_default": "8192", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/>8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT."}]
source_paths: ["Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastBigInt.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# TVF_TryCastBigInt

## Zweck und Einsatzfälle

Prüft ASCII-Ganzzahltext und den exakten bigint-Bereich; liefert Value, Status und ErrorCode.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Vorhandenes SELECT; genau eine Zeile, keine Seiteneffekte.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | ASCII-Dezimaltext mit mindestens einer Ziffer 0..9 und optional einem führenden + oder -. Führende Nullen/negative Null sind zulässig. Kein Trim, kein Unicode-Ziffernersatz, Dezimalpunkt, Exponent oder Tausendertrennzeichen. Zielbereich -9223372036854775808..9223372036854775807. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/&gt;8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_conversion.TVF_TryCastBigInt(N'-9223372036854775808', DEFAULT);
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
- `Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastBigInt.md`

Keine Installations-, Definitions- oder Rechteattestation.
