---
name: "toolbelt-toolbelt-toolbelt-metadata-svf-quotemultipartname"
description: "Validiert einen mehrteiligen SQL-Namen und quotiert seine Komponenten."
skill_format_version: "1.0"
module_id: "toolbelt.metadata.identifier"
schema_name: "toolbelt_metadata"
object_name: "SVF_QuoteMultipartName"
object_type: "SVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@MultipartName", "sql_type": "nvarchar(1035)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Ein- bis vierteiliger SQL-Identifier als nvarchar(1035), je ausgeschriebenem Teil höchstens 128 Zeichen. Formen: Object; Schema.Object; Database.Schema.Object; Server.Database.Schema.Object; Database..Object; Server.Database..Object; Server..Schema.Object; Server...Object. Eckige Klammern erlauben Punkte im Teil und ]] als escaped Schlussklammer. Keine doppelten Quotes als Delimiter, äußeren Spaces, leeren Objektteile oder Steuerzeichen. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit ValidationCode, beim Scalarwrapper NULL. Existenz und Rechte werden nicht dadurch geprüft."}]
source_paths: ["Modules/toolbelt.metadata.identifier/Source/SVF_QuoteMultipartName.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# SVF_QuoteMultipartName

## Zweck und Einsatzfälle

Validiert einen mehrteiligen SQL-Namen und quotiert seine Komponenten.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@MultipartName` | `nvarchar(1035)` | `kein Default` | Input | Ein- bis vierteiliger SQL-Identifier als nvarchar(1035), je ausgeschriebenem Teil höchstens 128 Zeichen. Formen: Object; Schema.Object; Database.Schema.Object; Server.Database.Schema.Object; Database..Object; Server.Database..Object; Server..Schema.Object; Server...Object. Eckige Klammern erlauben Punkte im Teil und ]] als escaped Schlussklammer. Keine doppelten Quotes als Delimiter, äußeren Spaces, leeren Objektteile oder Steuerzeichen. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit ValidationCode, beim Scalarwrapper NULL. Existenz und Rechte werden nicht dadurch geprüft. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT toolbelt_metadata.SVF_QuoteMultipartName(N'dbo.[Order Items]') AS ResultValue;
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
- `Modules/toolbelt.metadata.identifier/Documentation/SVF_QuoteMultipartName.md`

Keine Installations-, Definitions- oder Rechteattestation.
