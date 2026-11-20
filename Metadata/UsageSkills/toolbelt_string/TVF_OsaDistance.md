---
name: "toolbelt-toolbelt-toolbelt-string-tvf-osadistance"
description: "Berechnet die begrenzte Optimal-String-Alignment-Distanz mit benachbarten Transpositionen."
skill_format_version: "1.0"
module_id: "toolbelt.string.edit-distance"
schema_name: "toolbelt_string"
object_name: "TVF_OsaDistance"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@LeftText", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Unicode-Text ohne automatische Normalisierung oder Casefolding; leer ist gültig. Verarbeitung zählt Unicode-Skalarwerte, nicht Graphemcluster. Grenzen je Profile: standard 2048 UTF-16-Einheiten/1024 Skalare, large 65536/32768. Ungültige Surrogatfolgen ergeben ErrorCode 4; Überschreitung der UTF-16-Grenze ergibt Code 3, der Skalargrenze Code 5; geplantes Worklimit Code 6. Ist einer der beiden Texte NULL, entsteht eine NULL-Ergebniszeile vor Profil-/Schwellenprüfung."}, {"name": "@RightText", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Unicode-Text ohne automatische Normalisierung oder Casefolding; leer ist gültig. Verarbeitung zählt Unicode-Skalarwerte, nicht Graphemcluster. Grenzen je Profile: standard 2048 UTF-16-Einheiten/1024 Skalare, large 65536/32768. Ungültige Surrogatfolgen ergeben ErrorCode 4; Überschreitung der UTF-16-Grenze ergibt Code 3, der Skalargrenze Code 5; geplantes Worklimit Code 6. Ist einer der beiden Texte NULL, entsteht eine NULL-Ergebniszeile vor Profil-/Schwellenprüfung."}, {"name": "@MaxDistance", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "NULL (Default) berechnet ohne Distanzschwelle. Ganzzahl 0..2147483647 begrenzt die gesuchte Distanz; 0 verlangt Gleichheit. Bei Überschreitung ExceedsMaxDistance auswerten, keinen exakten Vollabstand unterstellen. Negative Werte ergeben ErrorCode 2, sofern kein früher NULL-Textpfad greift."}, {"name": "@Profile", "sql_type": "nvarchar(max)", "sql_default": "N'standard'", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) = höchstens 2048 UTF-16-Einheiten, 1024 Skalare pro Text und 1048576 geplante Arbeitseinheiten; large = 65536 Einheiten, 32768 Skalare und 16777216 Arbeitseinheiten. NULL/leer/andere Schreibweisen ergeben ErrorCode 1, außer beim frühen NULL-Textpfad. Größeres Profil hebt die endlichen Worklimits nicht auf."}]
source_paths: ["Modules/toolbelt.string.edit-distance/Source/EditDistance.sql"]
review_status: "draft"
source_module_version: "1.1.0"
---

# TVF_OsaDistance

## Zweck und Einsatzfälle

Berechnet die begrenzte Optimal-String-Alignment-Distanz mit benachbarten Transpositionen.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeftText` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text ohne automatische Normalisierung oder Casefolding; leer ist gültig. Verarbeitung zählt Unicode-Skalarwerte, nicht Graphemcluster. Grenzen je Profile: standard 2048 UTF-16-Einheiten/1024 Skalare, large 65536/32768. Ungültige Surrogatfolgen ergeben ErrorCode 4; Überschreitung der UTF-16-Grenze ergibt Code 3, der Skalargrenze Code 5; geplantes Worklimit Code 6. Ist einer der beiden Texte NULL, entsteht eine NULL-Ergebniszeile vor Profil-/Schwellenprüfung. |
| `@RightText` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text ohne automatische Normalisierung oder Casefolding; leer ist gültig. Verarbeitung zählt Unicode-Skalarwerte, nicht Graphemcluster. Grenzen je Profile: standard 2048 UTF-16-Einheiten/1024 Skalare, large 65536/32768. Ungültige Surrogatfolgen ergeben ErrorCode 4; Überschreitung der UTF-16-Grenze ergibt Code 3, der Skalargrenze Code 5; geplantes Worklimit Code 6. Ist einer der beiden Texte NULL, entsteht eine NULL-Ergebniszeile vor Profil-/Schwellenprüfung. |
| `@MaxDistance` | `int` | `NULL` | Input | NULL (Default) berechnet ohne Distanzschwelle. Ganzzahl 0..2147483647 begrenzt die gesuchte Distanz; 0 verlangt Gleichheit. Bei Überschreitung ExceedsMaxDistance auswerten, keinen exakten Vollabstand unterstellen. Negative Werte ergeben ErrorCode 2, sofern kein früher NULL-Textpfad greift. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) = höchstens 2048 UTF-16-Einheiten, 1024 Skalare pro Text und 1048576 geplante Arbeitseinheiten; large = 65536 Einheiten, 32768 Skalare und 16777216 Arbeitseinheiten. NULL/leer/andere Schreibweisen ergeben ErrorCode 1, außer beim frühen NULL-Textpfad. Größeres Profil hebt die endlichen Worklimits nicht auf. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_string.TVF_OsaDistance(N'kitten', N'sitting', NULL, N'standard');
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
- `Modules/toolbelt.string.edit-distance/Documentation/TVF_OsaDistance.md`

Keine Installations-, Definitions- oder Rechteattestation.
