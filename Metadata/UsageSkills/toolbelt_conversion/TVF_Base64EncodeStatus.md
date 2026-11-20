---
name: "toolbelt-toolbelt-toolbelt-conversion-tvf-base64encodestatus"
description: "Genau eine Zeile. OK enthält den Wert; LIMIT und SQL_NULL enthalten NULL. Der kanonische MSTVF-Kern prüft vor XML. Die bisherige TVF/SVF delegiert und liefert bei Überschreitung NULL."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.base64"
schema_name: "toolbelt_conversion"
object_name: "TVF_Base64EncodeStatus"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL."}, {"name": "@UrlSafe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt."}]
source_paths: ["Modules/toolbelt.conversion.base64/Source/TVF_Base64Encode.sql"]
review_status: "draft"
source_module_version: "1.1.0"
---

# TVF_Base64EncodeStatus

## Zweck und Einsatzfälle

Genau eine Zeile. OK enthält den Wert; LIMIT und SQL_NULL enthalten NULL. Der kanonische MSTVF-Kern prüft vor XML. Die bisherige TVF/SVF delegiert und liefert bei Überschreitung NULL.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varbinary(max)` | `kein Default` | Input | Binärwert varbinary(max), etwa 0xCAFECAFE oder ein vom Client gebundener Bytepuffer; keine Text-Decodierung. Leer (0x) ist gültig. Maximal 16777216 Bytes; darüber Status LIMIT bzw. NULL in der Wertfassade. NULL ergibt SQL_NULL bzw. NULL. |
| `@UrlSafe` | `bit` | `0` | Input | Taxativ für den gebundenen bit-Wert: 0 erzeugt Standard-Base64 mit +, / und Padding = (Default); 1 erzeugt Base64URL mit -, _ und ohne Padding. NULL wird wie 0 behandelt. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_conversion.TVF_Base64EncodeStatus(0xCAFE,0);
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
- `Modules/toolbelt.conversion.base64/Documentation/TVF_Base64EncodeStatus.md`

Keine Installations-, Definitions- oder Rechteattestation.
