---
name: "toolbelt-toolbelt-toolbelt-conversion-svf-base64encode"
description: "Codiert Binärdaten als Base64 oder Base64URL."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.base64"
schema_name: "toolbelt_conversion"
object_name: "SVF_Base64Encode"
object_type: "SVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL."}, {"name": "@UrlSafe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt."}]
source_paths: ["Modules/toolbelt.conversion.base64/Source/SVF_Base64Encode.sql"]
review_status: "draft"
source_module_version: "1.1.0"
---

# SVF_Base64Encode

## Zweck und Einsatzfälle

Codiert Binärdaten als Base64 oder Base64URL.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varbinary(max)` | `kein Default` | Input | Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL. |
| `@UrlSafe` | `bit` | `0` | Input | Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT toolbelt_conversion.SVF_Base64Encode(0x4869, 0) AS ResultValue;
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
- `Modules/toolbelt.conversion.base64/Documentation/SVF_Base64Encode.md`

Keine Installations-, Definitions- oder Rechteattestation.
