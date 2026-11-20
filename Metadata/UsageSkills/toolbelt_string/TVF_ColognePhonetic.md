---
name: "toolbelt-toolbelt-toolbelt-string-tvf-colognephonetic"
description: "Berechnet den vollständigen begrenzten Kölner Phonetikcode."
skill_format_version: "1.0"
module_id: "toolbelt.string.phonetic"
schema_name: "toolbelt_string"
object_name: "TVF_ColognePhonetic"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Text", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Rohtext mit höchstens 4096 UTF-16-Einheiten; gültige Surrogatpaare werden geprüft, ein nicht unterstützter Skalar wird nicht still entfernt. ASCII-Zeichen sind zulässig. NULL ergibt NULL-Code(s)/ErrorCode 0; leer ist gültig. Längen-/Arbeitsgrenze ergibt Code 2, ungepaarte Surrogate Code 1 und nicht unterstützte Zeichen Code 3. Keine frei wählbare Sprache/Transliteration. Zusätzlich zu ASCII sind ÄÖÜäöüß erlaubt; Umlaute werden A/O/U und ß wird SS. Kein allgemeiner Unicode-Phonetikdienst."}]
source_paths: ["Modules/toolbelt.string.phonetic/Source/TVF_ColognePhonetic.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# TVF_ColognePhonetic

## Zweck und Einsatzfälle

Berechnet den vollständigen begrenzten Kölner Phonetikcode.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Text` | `nvarchar(max)` | `kein Default` | Input | Rohtext mit höchstens 4096 UTF-16-Einheiten; gültige Surrogatpaare werden geprüft, ein nicht unterstützter Skalar wird nicht still entfernt. ASCII-Zeichen sind zulässig. NULL ergibt NULL-Code(s)/ErrorCode 0; leer ist gültig. Längen-/Arbeitsgrenze ergibt Code 2, ungepaarte Surrogate Code 1 und nicht unterstützte Zeichen Code 3. Keine frei wählbare Sprache/Transliteration. Zusätzlich zu ASCII sind ÄÖÜäöüß erlaubt; Umlaute werden A/O/U und ß wird SS. Kein allgemeiner Unicode-Phonetikdienst. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_string.TVF_ColognePhonetic(N'Contoso');
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
- `Modules/toolbelt.string.phonetic/Documentation/TVF_ColognePhonetic.md`

Keine Installations-, Definitions- oder Rechteattestation.
