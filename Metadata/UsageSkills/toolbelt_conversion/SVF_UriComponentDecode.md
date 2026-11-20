---
name: "toolbelt-toolbelt-toolbelt-conversion-svf-uricomponentdecode"
description: "Decodiert eine Runde von Prozent-Escapes und prüft die UTF-8-Sequenz."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.uri-component"
schema_name: "toolbelt_conversion"
object_name: "SVF_UriComponentDecode"
object_type: "SVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "ASCII-Text mit optionalen %HH-Triplets als UTF-8-Bytes, maximal 65536 UTF-16-Bytes. Genau eine Decodierrunde; + bleibt +, leerer Text ist gültig. Nicht-ASCII-Rohtext, fehlerhafte Triplets, ungültiges UTF-8 und decodiertes NUL sind ungültig (Codes 10..13). NULL ergibt NULL-Felder/SQL_NULL; Überschreitung Code 14/LIMIT, Wert NULL."}]
source_paths: ["Modules/toolbelt.conversion.uri-component/Source/SVF_UriComponentDecode.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# SVF_UriComponentDecode

## Zweck und Einsatzfälle

Decodiert eine Runde von Prozent-Escapes und prüft die UTF-8-Sequenz.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | ASCII-Text mit optionalen %HH-Triplets als UTF-8-Bytes, maximal 65536 UTF-16-Bytes. Genau eine Decodierrunde; + bleibt +, leerer Text ist gültig. Nicht-ASCII-Rohtext, fehlerhafte Triplets, ungültiges UTF-8 und decodiertes NUL sind ungültig (Codes 10..13). NULL ergibt NULL-Felder/SQL_NULL; Überschreitung Code 14/LIMIT, Wert NULL. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT toolbelt_conversion.SVF_UriComponentDecode(N'a%20b%2F%C3%A4') AS ResultValue;
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
- `Modules/toolbelt.conversion.uri-component/Documentation/SVF_UriComponentDecode.md`

Keine Installations-, Definitions- oder Rechteattestation.
