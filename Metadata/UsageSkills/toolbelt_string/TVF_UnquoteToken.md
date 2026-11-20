---
name: "toolbelt-toolbelt-toolbelt-string-tvf-unquotetoken"
description: "Entfernt ein unterstütztes äußeres Quote-Paar und decodiert dessen Escapes."
skill_format_version: "1.0"
module_id: "toolbelt.string.split-advanced"
schema_name: "toolbelt_string"
object_name: "TVF_UnquoteToken"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Ein Token mit maximal 65536 UTF-16-Einheiten; leer ist gültig, NUL verboten. NULL liefert vor jeder Konfigurationsprüfung keine Zeile. Erkannte/explicit verlangte äußere Qualifier werden entfernt; ein unescaped inneres Closing-Zeichen ergibt eine ungültige Ergebniszeile."}, {"name": "@Qualifier", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "NULL (Default) erkennt nur direkt am Rand die Paare Doppelquote/Doppelquote, Apostroph/Apostroph, [/], “/” oder „/“; keine Rand-Whitespacebereinigung. Kein erkanntes Paar lässt den Token unverändert. Leer deaktiviert Unquote und verlangt ClosingQualifier=NULL. Explizit genau eine UTF-16-Einheit, weder NUL noch Surrogat; mit ClosingQualifier=NULL werden [ und ] zu [/], “ und ” zu “/”, „ zu „/“, andere Zeichen zu identischen Öffnern/Schließern normalisiert."}, {"name": "@ClosingQualifier", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "NULL (Default) verwendet das aus Qualifier abgeleitete Paar beziehungsweise die automatische Erkennung. Andernfalls genau eine nicht-NUL-/nicht-Surrogat-UTF-16-Einheit, nur zusammen mit einem expliziten nicht leeren Qualifier. Erfordert genau dieses Außenpaar; bei BackslashEscape=1 darf kein Qualifier Backslash sein."}, {"name": "@BackslashEscape", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ im gebundenen bit: 0 erkennt nur verdoppelte Closing-Zeichen (Default); 1 erkennt zusätzlich Backslash vor Öffner, Schließer oder Backslash. NULL wirkt wie 0. Keine JSON-/C-Interpretation von \\n, \\t usw.; Backslash darf im aktiven Modus kein Qualifier sein."}]
source_paths: ["Modules/toolbelt.string.split-advanced/Source/TVF_UnquoteToken.sql"]
review_status: "draft"
source_module_version: "1.1.0"
---

# TVF_UnquoteToken

## Zweck und Einsatzfälle

Entfernt ein unterstütztes äußeres Quote-Paar und decodiert dessen Escapes.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Ein Token mit maximal 65536 UTF-16-Einheiten; leer ist gültig, NUL verboten. NULL liefert vor jeder Konfigurationsprüfung keine Zeile. Erkannte/explicit verlangte äußere Qualifier werden entfernt; ein unescaped inneres Closing-Zeichen ergibt eine ungültige Ergebniszeile. |
| `@Qualifier` | `nvarchar(max)` | `NULL` | Input | NULL (Default) erkennt nur direkt am Rand die Paare Doppelquote/Doppelquote, Apostroph/Apostroph, [/], “/” oder „/“; keine Rand-Whitespacebereinigung. Kein erkanntes Paar lässt den Token unverändert. Leer deaktiviert Unquote und verlangt ClosingQualifier=NULL. Explizit genau eine UTF-16-Einheit, weder NUL noch Surrogat; mit ClosingQualifier=NULL werden [ und ] zu [/], “ und ” zu “/”, „ zu „/“, andere Zeichen zu identischen Öffnern/Schließern normalisiert. |
| `@ClosingQualifier` | `nvarchar(max)` | `NULL` | Input | NULL (Default) verwendet das aus Qualifier abgeleitete Paar beziehungsweise die automatische Erkennung. Andernfalls genau eine nicht-NUL-/nicht-Surrogat-UTF-16-Einheit, nur zusammen mit einem expliziten nicht leeren Qualifier. Erfordert genau dieses Außenpaar; bei BackslashEscape=1 darf kein Qualifier Backslash sein. |
| `@BackslashEscape` | `bit` | `0` | Input | Taxativ im gebundenen bit: 0 erkennt nur verdoppelte Closing-Zeichen (Default); 1 erkennt zusätzlich Backslash vor Öffner, Schließer oder Backslash. NULL wirkt wie 0. Keine JSON-/C-Interpretation von \n, \t usw.; Backslash darf im aktiven Modus kein Qualifier sein. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_string.TVF_UnquoteToken(N'[a]]b]', NULL, NULL, 0);
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
- `Modules/toolbelt.string.split-advanced/Documentation/TVF_UnquoteToken.md`

Keine Installations-, Definitions- oder Rechteattestation.
