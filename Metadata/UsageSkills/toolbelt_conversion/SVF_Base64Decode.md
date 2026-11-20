---
name: "toolbelt-toolbelt-toolbelt-conversion-svf-base64decode"
description: "Decodiert Base64-Text zu Binärdaten."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.base64"
schema_name: "toolbelt_conversion"
object_name: "SVF_Base64Decode"
object_type: "SVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "varchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "ASCII-Base64-Text (A-Z, a-z, 0-9, +, /) oder Base64URL (-, _ statt +, /); beide Alphabete werden normalisiert. Nur Space, Tab, CR und LF werden entfernt. Optionales =-Padding nur am Ende in passender Länge; ohne Padding sind Restlängen 0, 2 oder 3 modulo 4 gültig. Leer/Whitespace-only ergibt leere Bytes. Höchstens 25165824 Rohtextbytes und 16777216 Ergebnisbytes; NULL ergibt SQL_NULL/NULL, Überschreitung LIMIT/NULL. Ungültige Syntax ergibt INVALID im Statuskern, einen Konvertierungsfehler in TVF/SVF-Wertfassaden."}]
source_paths: ["Modules/toolbelt.conversion.base64/Source/SVF_Base64Decode.sql"]
review_status: "draft"
source_module_version: "1.1.0"
---

# SVF_Base64Decode

## Zweck und Einsatzfälle

Decodiert Base64-Text zu Binärdaten.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `varchar(max)` | `kein Default` | Input | ASCII-Base64-Text (A-Z, a-z, 0-9, +, /) oder Base64URL (-, _ statt +, /); beide Alphabete werden normalisiert. Nur Space, Tab, CR und LF werden entfernt. Optionales =-Padding nur am Ende in passender Länge; ohne Padding sind Restlängen 0, 2 oder 3 modulo 4 gültig. Leer/Whitespace-only ergibt leere Bytes. Höchstens 25165824 Rohtextbytes und 16777216 Ergebnisbytes; NULL ergibt SQL_NULL/NULL, Überschreitung LIMIT/NULL. Ungültige Syntax ergibt INVALID im Statuskern, einen Konvertierungsfehler in TVF/SVF-Wertfassaden. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT toolbelt_conversion.SVF_Base64Decode(N'SGk=') AS ResultValue;
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
- `Modules/toolbelt.conversion.base64/Documentation/SVF_Base64Decode.md`

Keine Installations-, Definitions- oder Rechteattestation.
