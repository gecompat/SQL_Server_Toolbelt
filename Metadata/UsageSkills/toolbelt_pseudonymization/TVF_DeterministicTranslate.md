---
name: "toolbelt-toolbelt-toolbelt-pseudonymization-tvf-determi-068cfec0"
description: "Übersetzt ASCII-Buchstaben und Ziffern deterministisch über eine bijektive Abbildung."
skill_format_version: "1.0"
module_id: "toolbelt.pseudonymization.deterministic"
schema_name: "toolbelt_pseudonymization"
object_name: "TVF_DeterministicTranslate"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "ASCII-Kennung: Buchstaben a-z/A-Z und Ziffern 0-9 werden bijektiv substituiert, ausdrücklich erlaubte Separatoren bleiben unverändert. Leer ist gültig; NULL ergibt NULL/Code 0 vor jeder Konfigurationsprüfung. Kein Trim/Unicode-Transliterieren; Akzente, NUL, Controls, DEL und Surrogate ergeben Code 13. Bytebudget durch Profile, Output exakt gleiche Länge."}, {"name": "@MappingVersion", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert."}, {"name": "@Seed", "sql_type": "bigint", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad."}, {"name": "@AllowedSeparators", "sql_type": "nvarchar(max)", "sql_default": "N''", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Explizite Menge von höchstens 33 verschiedenen druckbaren ASCII-Nichtalnum-Zeichen aus Codes 32..126, z.B. N'-/ '; jedes bleibt unverändert. Leer (Default) erlaubt keine Separatoren. Duplikate, Buchstaben/Ziffern, Controls/NUL/DEL/Unicode und NULL ergeben Code 11; trailing Spaces sind relevant. Keine mehrzeichige Separatorgrammatik."}, {"name": "@Profile", "sql_type": "nvarchar(max)", "sql_default": "N'standard'", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ, bytegenau ohne Trim: standard (Default) = höchstens 2097152 UTF-16-Inputbytes; large = höchstens 16777216. NULL/leer/andere Schreibweisen ergeben Code 10; Überschreitung Code 12. Profil ändert nur das Budget, nicht die Mappingpermutation."}]
source_paths: ["Modules/toolbelt.pseudonymization.deterministic/Source/DeterministicTranslate.sql"]
review_status: "draft"
source_module_version: "1.2.0"
---

# TVF_DeterministicTranslate

## Zweck und Einsatzfälle

Übersetzt ASCII-Buchstaben und Ziffern deterministisch über eine bijektive Abbildung.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | ASCII-Kennung: Buchstaben a-z/A-Z und Ziffern 0-9 werden bijektiv substituiert, ausdrücklich erlaubte Separatoren bleiben unverändert. Leer ist gültig; NULL ergibt NULL/Code 0 vor jeder Konfigurationsprüfung. Kein Trim/Unicode-Transliterieren; Akzente, NUL, Controls, DEL und Surrogate ergeben Code 13. Bytebudget durch Profile, Output exakt gleiche Länge. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@AllowedSeparators` | `nvarchar(max)` | `N''` | Input | Explizite Menge von höchstens 33 verschiedenen druckbaren ASCII-Nichtalnum-Zeichen aus Codes 32..126, z.B. N'-/ '; jedes bleibt unverändert. Leer (Default) erlaubt keine Separatoren. Duplikate, Buchstaben/Ziffern, Controls/NUL/DEL/Unicode und NULL ergeben Code 11; trailing Spaces sind relevant. Keine mehrzeichige Separatorgrammatik. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, bytegenau ohne Trim: standard (Default) = höchstens 2097152 UTF-16-Inputbytes; large = höchstens 16777216. NULL/leer/andere Schreibweisen ergeben Code 10; Überschreitung Code 12. Profil ändert nur das Budget, nicht die Mappingpermutation. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(N'  Contoso-123  ', 1, 42, N'- ', N'standard');
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
- `Modules/toolbelt.pseudonymization.deterministic/Documentation/TVF_DeterministicTranslate.md`

Keine Installations-, Definitions- oder Rechteattestation.
