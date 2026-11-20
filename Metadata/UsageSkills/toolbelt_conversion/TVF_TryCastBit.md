---
name: "toolbelt-toolbelt-toolbelt-conversion-tvf-trycastbit"
description: "Akzeptiert ausschließlich den Text0 oder1; native permissive Bitkonversion bleibt ausgeschlossen."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.safe-cast"
schema_name: "toolbelt_conversion"
object_name: "TVF_TryCastBit"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Text", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ als Text: N'0' ergibt bit 0; N'1' ergibt bit 1. Keine anderen Werte, Vorzeichen, TRUE/FALSE, Spaces oder Normalisierung; dies ist ein strikter Textparser und nicht die native bit-Konvertierung. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen."}, {"name": "@MaxInputBytes", "sql_type": "int", "sql_default": "8192", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/>8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT."}]
source_paths: ["Modules/toolbelt.conversion.safe-cast/Source/TVF_TryCastBit.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# TVF_TryCastBit

## Zweck und Einsatzfälle

Akzeptiert ausschließlich den Text0 oder1; native permissive Bitkonversion bleibt ausgeschlossen.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Vorhandenes SELECT; Bit2 und TRUE sind INVALID_FORMAT.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Taxativ als Text: N'0' ergibt bit 0; N'1' ergibt bit 1. Keine anderen Werte, Vorzeichen, TRUE/FALSE, Spaces oder Normalisierung; dies ist ein strikter Textparser und nicht die native bit-Konvertierung. NULL ergibt SQL_NULL, leerer Text EMPTY; sonst ungültige Lexik INVALID_FORMAT, kein stilles Trimmen. |
| `@MaxInputBytes` | `int` | `8192` | Input | Positives int-Bytebudget 1..8192 einschließlich (Default 8192), gemessen mit DATALENGTH des UTF-16-Texts, nicht in Zeichen; auch ungerade Budgets sind zulässig. NULL/0/negativ/&gt;8192 ergibt INVALID_ARGUMENT/PARAMETER, außer Text=NULL hat Vorrang (SQL_NULL). Ein größerer Text ergibt LIMIT/INPUT_LIMIT. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_conversion.TVF_TryCastBit(N'2', DEFAULT);
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
- `Modules/toolbelt.conversion.safe-cast/Documentation/TVF_TryCastBit.md`

Keine Installations-, Definitions- oder Rechteattestation.
